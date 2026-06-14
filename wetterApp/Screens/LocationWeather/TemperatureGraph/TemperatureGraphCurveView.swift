//
//  TemperatureGraphCurveView.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 14.06.2026.
//

import UIKit

/// A custom view that renders a temperature graph using cubic Bézier curves.
/// It draws the connection between the previous, current, and next temperature
/// points smoothly across collection view cells.
final class TemperatureGraphCurveView: UIView {

    /// Holds the required temperature data to calculate the curve geometry.
    struct Configuration: Equatable {
        let currentTemperature: Double
        let previousTemperature: Double?
        let nextTemperature: Double?
        let minimumTemperature: Double
        let maximumTemperature: Double
    }

    private static let lineWidth: CGFloat = 2
    private static let pointRadius: CGFloat = 4

    /// The layer responsible for drawing the left half of the curve (connecting the previous point to the current point).
    let leftCurveLayer = CAShapeLayer()
    
    /// The layer responsible for drawing the right half of the curve (connecting the current point to the next point).
    let rightCurveLayer = CAShapeLayer()
    
    /// The layer responsible for drawing the circular indicator at the current temperature point.
    let pointLayer = CAShapeLayer()

    /// The layer responsible for filling the area under the left half of the curve.
    let leftFillLayer = CAShapeLayer()

    /// The layer responsible for filling the area under the right half of the curve.
    let rightFillLayer = CAShapeLayer()

    /// The current configuration data used for rendering.
    private(set) var configuration: Configuration?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Recalculate curve paths whenever the view's bounds change (e.g. rotation, resizing).
        updatePaths()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    /// Configures the view with new temperature data and requests a layout update.
    ///
    /// - Parameters:
    ///   - currentTemperature: The temperature for the current hour/cell.
    ///   - previousTemperature: The temperature for the previous hour/cell, if available.
    ///   - nextTemperature: The temperature for the next hour/cell, if available.
    ///   - minimumTemperature: The minimum temperature across the entire visible graph data.
    ///   - maximumTemperature: The maximum temperature across the entire visible graph data.
    func configure(
        currentTemperature: Double,
        previousTemperature: Double?,
        nextTemperature: Double?,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) {
        configuration = Configuration(
            currentTemperature: currentTemperature,
            previousTemperature: previousTemperature,
            nextTemperature: nextTemperature,
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature
        )
        setNeedsLayout()
    }

    /// Clears the current configuration and removes the drawn paths.
    func reset() {
        configuration = nil
        clearPaths()
    }

    /// Calculates the precise geometry required to draw the cubic Bézier curves for this cell.
    /// 
    /// This method uses De Casteljau's algorithm to split a full curve between two temperature
    /// points exactly in half (t = 0.5), allowing each cell to render its own half of the curve
    /// independently while ensuring perfectly matching positions and tangents at the cell boundary.
    static func makeGeometry(
        in bounds: CGRect,
        configuration: Configuration
    ) -> TemperatureGraphCurveGeometry {
        let currentY = yPosition(
            for: configuration.currentTemperature,
            in: bounds,
            minimumTemperature: configuration.minimumTemperature,
            maximumTemperature: configuration.maximumTemperature
        )
        // The current point is always centered horizontally in the cell.
        let currentPoint = CGPoint(x: bounds.midX, y: currentY)

        let w = bounds.width

        var leftSegment: TemperatureGraphCurveSegment?
        // Calculate the left segment if there is a previous temperature point.
        if let previousTemperature = configuration.previousTemperature {
            let prevY = yPosition(
                for: previousTemperature,
                in: bounds,
                minimumTemperature: configuration.minimumTemperature,
                maximumTemperature: configuration.maximumTemperature
            )
            // The left segment draws from the left edge of the cell (bounds.minX) to the center (bounds.midX).
            // It represents the right half of the curve that connects the previous point to the current point.
            leftSegment = TemperatureGraphCurveSegment(
                startPoint: CGPoint(x: bounds.minX, y: (prevY + currentY) / 2.0),
                firstControlPoint: CGPoint(x: bounds.minX + w / 6.0, y: (prevY + 3.0 * currentY) / 4.0),
                secondControlPoint: CGPoint(x: bounds.minX + w / 3.0, y: currentY),
                endPoint: currentPoint
            )
        }

        var rightSegment: TemperatureGraphCurveSegment?
        // Calculate the right segment if there is a next temperature point.
        if let nextTemperature = configuration.nextTemperature {
            let nextY = yPosition(
                for: nextTemperature,
                in: bounds,
                minimumTemperature: configuration.minimumTemperature,
                maximumTemperature: configuration.maximumTemperature
            )
            // The right segment draws from the center of the cell (bounds.midX) to the right edge (bounds.maxX).
            // It represents the left half of the curve that connects the current point to the next point.
            rightSegment = TemperatureGraphCurveSegment(
                startPoint: currentPoint,
                firstControlPoint: CGPoint(x: bounds.midX + w / 6.0, y: currentY),
                secondControlPoint: CGPoint(x: bounds.midX + w / 3.0, y: (3.0 * currentY + nextY) / 4.0),
                endPoint: CGPoint(x: bounds.maxX, y: (currentY + nextY) / 2.0)
            )
        }

        return TemperatureGraphCurveGeometry(
            leftSegment: leftSegment,
            currentPoint: currentPoint,
            rightSegment: rightSegment
        )
    }
}

// MARK: - Setup

private extension TemperatureGraphCurveView {

    /// Configures the base appearance of the shape layers and adds them to the view.
    func setupLayers() {
        isOpaque = false

        [leftFillLayer, rightFillLayer].forEach {
            $0.lineWidth = 0
            layer.addSublayer($0)
        }

        [leftCurveLayer, rightCurveLayer].forEach {
            $0.fillColor = nil
            $0.lineCap = .round
            $0.lineJoin = .round
            $0.lineWidth = Self.lineWidth
            layer.addSublayer($0)
        }
        layer.addSublayer(pointLayer)

        updateColors()
    }

    /// Synchronizes the stroke and fill colors of the layers with the view's current tint color.
    func updateColors() {
        let strokeColor = UIColor.label.cgColor
        let fillColor = UIColor.systemGray4.cgColor

        leftCurveLayer.strokeColor = strokeColor
        rightCurveLayer.strokeColor = strokeColor
        pointLayer.fillColor = strokeColor

        leftFillLayer.fillColor = fillColor
        rightFillLayer.fillColor = fillColor
    }
}

// MARK: - Drawing

private extension TemperatureGraphCurveView {

    /// Updates the `CGPath` for all layers based on the current configuration and bounds.
    func updatePaths() {
        guard let configuration else {
            clearPaths()
            return
        }

        let geometry = Self.makeGeometry(
            in: bounds,
            configuration: configuration
        )

        // Disable implicit animations to prevent visual jumps during layout updates or cell recycling.
        CATransaction.begin()
        CATransaction.setDisableActions(true)

        leftCurveLayer.frame = bounds
        rightCurveLayer.frame = bounds
        leftFillLayer.frame = bounds
        rightFillLayer.frame = bounds
        pointLayer.frame = bounds
        
        leftCurveLayer.path = curvePath(for: geometry.leftSegment)
        rightCurveLayer.path = curvePath(for: geometry.rightSegment)
        
        leftFillLayer.path = fillPath(for: geometry.leftSegment, bounds: bounds)
        rightFillLayer.path = fillPath(for: geometry.rightSegment, bounds: bounds)
        
        pointLayer.path = UIBezierPath(
            ovalIn: CGRect(
                x: geometry.currentPoint.x - Self.pointRadius,
                y: geometry.currentPoint.y - Self.pointRadius,
                width: Self.pointRadius * 2,
                height: Self.pointRadius * 2
            )
        ).cgPath

        CATransaction.commit()
    }

    /// Converts a `TemperatureGraphCurveSegment` into a `CGPath` using a cubic Bézier curve.
    func curvePath(for segment: TemperatureGraphCurveSegment?) -> CGPath? {
        guard let segment else {
            return nil
        }

        let path = UIBezierPath()
        path.move(to: segment.startPoint)
        path.addCurve(
            to: segment.endPoint,
            controlPoint1: segment.firstControlPoint,
            controlPoint2: segment.secondControlPoint
        )
        return path.cgPath
    }

    /// Converts a `TemperatureGraphCurveSegment` into a closed `CGPath` for filling the area beneath the curve.
    func fillPath(for segment: TemperatureGraphCurveSegment?, bounds: CGRect) -> CGPath? {
        guard let segment else {
            return nil
        }

        let path = UIBezierPath()
        path.move(to: segment.startPoint)
        path.addCurve(
            to: segment.endPoint,
            controlPoint1: segment.firstControlPoint,
            controlPoint2: segment.secondControlPoint
        )
        path.addLine(to: CGPoint(x: segment.endPoint.x, y: bounds.maxY))
        path.addLine(to: CGPoint(x: segment.startPoint.x, y: bounds.maxY))
        path.close()
        return path.cgPath
    }

    /// Removes all paths from the sublayers, making the graph invisible.
    func clearPaths() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        leftCurveLayer.path = nil
        rightCurveLayer.path = nil
        leftFillLayer.path = nil
        rightFillLayer.path = nil
        pointLayer.path = nil
        CATransaction.commit()
    }

    /// Normalizes a temperature value to a Y-coordinate within the view's bounds.
    ///
    /// - Returns: A vertical position where lower temperatures correspond to higher Y-coordinates (closer to the bottom edge).
    static func yPosition(
        for temperature: Double,
        in bounds: CGRect,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) -> CGFloat {
        let lowerBound = min(minimumTemperature, maximumTemperature)
        let upperBound = max(minimumTemperature, maximumTemperature)

        // If min and max temperatures are the same, plot the point perfectly in the middle.
        guard upperBound > lowerBound else {
            return bounds.midY
        }

        let normalizedValue = (temperature - lowerBound) / (upperBound - lowerBound)
        let clampedValue = min(max(normalizedValue, 0), 1)
        
        // Prevent the point from being clipped by the top or bottom edges.
        let verticalInset = min(Self.pointRadius, bounds.height / 2)
        let drawableHeight = max(bounds.height - verticalInset * 2, 0)

        // In iOS coordinates, 0 is at the top. Higher temperatures should be closer to the top.
        return bounds.maxY - verticalInset - CGFloat(clampedValue) * drawableHeight
    }
}
