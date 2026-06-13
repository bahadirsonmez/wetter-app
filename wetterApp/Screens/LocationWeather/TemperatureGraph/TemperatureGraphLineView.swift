import UIKit

final class TemperatureGraphLineView: UIView {

    struct Configuration: Equatable {

        let currentTemperature: Double
        let previousTemperature: Double?
        let nextTemperature: Double?
        let minimumTemperature: Double
        let maximumTemperature: Double
    }

    struct Geometry: Equatable {

        let previousPoint: CGPoint?
        let currentPoint: CGPoint
        let nextPoint: CGPoint?
    }

    private static let lineWidth: CGFloat = 2
    private static let pointRadius: CGFloat = 4

    let leftLineLayer = CAShapeLayer()
    let rightLineLayer = CAShapeLayer()
    let pointLayer = CAShapeLayer()

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

        // Recalculate paths whenever Auto Layout changes the graph area.
        updatePaths()
    }

    override func tintColorDidChange() {
        super.tintColorDidChange()

        // CAShapeLayer stores CGColor values, so refresh them when the
        // inherited tint changes.
        updateColors()
    }

    /// Stores the current point and its neighbors for the next layout pass.
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

    /// Removes reusable cell data and all currently rendered graph paths.
    func reset() {
        configuration = nil
        clearPaths()
    }

    /// Maps temperature values to the left edge, center, and right edge of
    /// the cell so adjacent cells can render matching half-line segments.
    static func makeGeometry(
        in bounds: CGRect,
        configuration: Configuration
    ) -> Geometry {
        let currentX = bounds.midX

        return Geometry(
            previousPoint: configuration.previousTemperature.map {
                CGPoint(
                    x: bounds.minX,
                    y: yPosition(
                        for: ($0 + configuration.currentTemperature) / 2.0,
                        in: bounds,
                        minimumTemperature:
                            configuration.minimumTemperature,
                        maximumTemperature:
                            configuration.maximumTemperature
                    )
                )
            },
            currentPoint: CGPoint(
                x: currentX,
                y: yPosition(
                    for: configuration.currentTemperature,
                    in: bounds,
                    minimumTemperature: configuration.minimumTemperature,
                    maximumTemperature: configuration.maximumTemperature
                )
            ),
            nextPoint: configuration.nextTemperature.map {
                CGPoint(
                    x: bounds.maxX,
                    y: yPosition(
                        for: ($0 + configuration.currentTemperature) / 2.0,
                        in: bounds,
                        minimumTemperature:
                            configuration.minimumTemperature,
                        maximumTemperature:
                            configuration.maximumTemperature
                    )
                )
            }
        )
    }
}

// MARK: - Setup

private extension TemperatureGraphLineView {

    /// Creates separate shape layers for both line halves and the center
    /// point, allowing the first and last segments to be omitted independently.
    func setupLayers() {
        isOpaque = false

        [leftLineLayer, rightLineLayer].forEach {
            $0.fillColor = nil
            $0.lineCap = .round
            $0.lineJoin = .round
            $0.lineWidth = Self.lineWidth
            layer.addSublayer($0)
        }
        layer.addSublayer(pointLayer)

        updateColors()
    }

    /// Applies the view's tint to the Core Animation layers.
    func updateColors() {
        let graphColor = tintColor.cgColor
        leftLineLayer.strokeColor = graphColor
        rightLineLayer.strokeColor = graphColor
        pointLayer.fillColor = graphColor
    }
}

// MARK: - Drawing

private extension TemperatureGraphLineView {

    /// Rebuilds the line and point paths from the latest bounds and
    /// configuration without triggering implicit Core Animation transitions.
    func updatePaths() {
        guard let configuration else {
            clearPaths()
            return
        }

        let geometry = Self.makeGeometry(
            in: bounds,
            configuration: configuration
        )

        CATransaction.begin()
        CATransaction.setDisableActions(true)

        leftLineLayer.frame = bounds
        rightLineLayer.frame = bounds
        pointLayer.frame = bounds
        leftLineLayer.path = linePath(
            from: geometry.previousPoint,
            to: geometry.currentPoint
        )
        rightLineLayer.path = linePath(
            from: geometry.currentPoint,
            to: geometry.nextPoint
        )
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

    /// Creates one half of the graph line, or no path when the corresponding
    /// neighboring forecast item does not exist.
    func linePath(
        from startPoint: CGPoint?,
        to endPoint: CGPoint?
    ) -> CGPath? {
        guard let startPoint, let endPoint else {
            return nil
        }

        let path = UIBezierPath()
        path.move(to: startPoint)
        path.addLine(to: endPoint)
        return path.cgPath
    }

    /// Clears all shape layers immediately when the view is reset or has no
    /// configuration.
    func clearPaths() {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        leftLineLayer.path = nil
        rightLineLayer.path = nil
        pointLayer.path = nil
        CATransaction.commit()
    }

    /// Normalizes a temperature into the drawable vertical range. Equal
    /// minimum and maximum values are placed at the vertical center.
    static func yPosition(
        for temperature: Double,
        in bounds: CGRect,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) -> CGFloat {
        let lowerBound = min(minimumTemperature, maximumTemperature)
        let upperBound = max(minimumTemperature, maximumTemperature)

        guard upperBound > lowerBound else {
            return bounds.midY
        }

        let normalizedValue = (
            temperature - lowerBound
        ) / (
            upperBound - lowerBound
        )
        let clampedValue = min(max(normalizedValue, 0), 1)
        let verticalInset = min(Self.pointRadius, bounds.height / 2)
        let drawableHeight = max(bounds.height - verticalInset * 2, 0)

        // Larger temperatures sit higher while the inset keeps the point
        // fully visible at both ends of the range.
        return bounds.maxY
            - verticalInset
            - CGFloat(clampedValue) * drawableHeight
    }
}
