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
        let previous2Temperature: Double?
        let previousTemperature: Double?
        let nextTemperature: Double?
        let next2Temperature: Double?
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
        previous2Temperature: Double?,
        previousTemperature: Double?,
        nextTemperature: Double?,
        next2Temperature: Double?,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) {
        configuration = Configuration(
            currentTemperature: currentTemperature,
            previous2Temperature: previous2Temperature,
            previousTemperature: previousTemperature,
            nextTemperature: nextTemperature,
            next2Temperature: next2Temperature,
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
        let currentTemp = configuration.currentTemperature
        let currentY = yPosition(
            for: currentTemp,
            in: bounds,
            minimumTemperature: configuration.minimumTemperature,
            maximumTemperature: configuration.maximumTemperature
        )
        // The current point is always centered horizontally in the cell.
        let currentPoint = CGPoint(x: bounds.midX, y: currentY)

        let w = bounds.width
        
        let yPos = { (temp: Double) -> CGFloat in
            return yPosition(
                for: temp,
                in: bounds,
                minimumTemperature: configuration.minimumTemperature,
                maximumTemperature: configuration.maximumTemperature
            )
        }

        var leftSegment: TemperatureGraphCurveSegment?
        // Calculate the left segment if there is a previous temperature point.
        if let previousTemp = configuration.previousTemperature {
            let (c1, c2) = globalControlPoints(
                beforeA: configuration.previous2Temperature,
                A: previousTemp,
                B: currentTemp,
                afterB: configuration.nextTemperature
            )
            let halves = splitBezier(p0: previousTemp, p1: c1, p2: c2, p3: currentTemp)
            let rightHalf = halves.rightHalf
            
            // The left segment draws from the left edge of the cell (bounds.minX) to the center (bounds.midX).
            leftSegment = TemperatureGraphCurveSegment(
                startPoint: CGPoint(x: bounds.minX, y: yPos(rightHalf.start)),
                firstControlPoint: CGPoint(x: bounds.minX + w / 6.0, y: yPos(rightHalf.c1)),
                secondControlPoint: CGPoint(x: bounds.minX + w / 3.0, y: yPos(rightHalf.c2)),
                endPoint: currentPoint
            )
        } else {
            leftSegment = TemperatureGraphCurveSegment(
                startPoint: CGPoint(x: bounds.minX, y: currentY),
                firstControlPoint: CGPoint(x: bounds.minX + w / 6.0, y: currentY),
                secondControlPoint: CGPoint(x: bounds.minX + w / 3.0, y: currentY),
                endPoint: currentPoint
            )
        }

        var rightSegment: TemperatureGraphCurveSegment?
        // Calculate the right segment if there is a next temperature point.
        if let nextTemp = configuration.nextTemperature {
            let (c1, c2) = globalControlPoints(
                beforeA: configuration.previousTemperature,
                A: currentTemp,
                B: nextTemp,
                afterB: configuration.next2Temperature
            )
            let halves = splitBezier(p0: currentTemp, p1: c1, p2: c2, p3: nextTemp)
            let leftHalf = halves.leftHalf
            
            // The right segment draws from the center of the cell (bounds.midX) to the right edge (bounds.maxX).
            rightSegment = TemperatureGraphCurveSegment(
                startPoint: currentPoint,
                firstControlPoint: CGPoint(x: bounds.midX + w / 6.0, y: yPos(leftHalf.c1)),
                secondControlPoint: CGPoint(x: bounds.midX + w / 3.0, y: yPos(leftHalf.c2)),
                endPoint: CGPoint(x: bounds.maxX, y: yPos(leftHalf.end))
            )
        } else {
            rightSegment = TemperatureGraphCurveSegment(
                startPoint: currentPoint,
                firstControlPoint: CGPoint(x: bounds.midX + w / 6.0, y: currentY),
                secondControlPoint: CGPoint(x: bounds.midX + w / 3.0, y: currentY),
                endPoint: CGPoint(x: bounds.maxX, y: currentY)
            )
        }

        return TemperatureGraphCurveGeometry(
            leftSegment: leftSegment,
            currentPoint: currentPoint,
            rightSegment: rightSegment
        )
    }
    
    /// Computes the intermediate Bézier control points for a cubic curve from A to B based on the Catmull-Rom spline formulation.
    private static func globalControlPoints(
        beforeA: Double?,
        A: Double,
        B: Double,
        afterB: Double?
    ) -> (first: Double, second: Double) {
        let mA = beforeA != nil ? (B - beforeA!) / 2.0 : B - A
        let mB = afterB != nil ? (afterB! - A) / 2.0 : B - A
        return (A + mA / 3.0, B - mB / 3.0)
    }
    
    /// Splits a cubic Bézier curve defined by 4 control points exactly in half at t = 0.5 using De Casteljau's algorithm.
    private static func splitBezier(
        p0: Double,
        p1: Double,
        p2: Double,
        p3: Double
    ) -> (
        leftHalf: (start: Double, c1: Double, c2: Double, end: Double),
        rightHalf: (start: Double, c1: Double, c2: Double, end: Double)
    ) {
        let m0 = (p0 + p1) / 2.0
        let m1 = (p1 + p2) / 2.0
        let m2 = (p2 + p3) / 2.0
        
        let q0 = (m0 + m1) / 2.0
        let q1 = (m1 + m2) / 2.0
        
        let mid = (q0 + q1) / 2.0
        
        return (
            leftHalf: (start: p0, c1: m0, c2: q0, end: mid),
            rightHalf: (start: mid, c1: q1, c2: m2, end: p3)
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
