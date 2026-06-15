import UIKit

final class TemperatureGraphCurveView: UIView {
    // MARK: - Properties

    private static let lineWidth: CGFloat = 2
    private static let pointRadius: CGFloat = 4

    let leftCurveLayer = CAShapeLayer()
    let rightCurveLayer = CAShapeLayer()
    let pointLayer = CAShapeLayer()
    let leftFillLayer = CAShapeLayer()
    let rightFillLayer = CAShapeLayer()

    private(set) var configuration: TemperatureGraphCurveConfiguration?

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()
        updatePaths()
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if traitCollection.hasDifferentColorAppearance(comparedTo: previousTraitCollection) {
            updateColors()
        }
    }

    // MARK: - Public Methods

    func configure(
        currentTemperature: Double,
        previous2Temperature: Double?,
        previousTemperature: Double?,
        nextTemperature: Double?,
        next2Temperature: Double?,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) {
        configuration = TemperatureGraphCurveConfiguration(
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

    func reset() {
        configuration = nil
        clearPaths()
    }
}

// MARK: - Setup

private extension TemperatureGraphCurveView {

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

    func updatePaths() {
        guard let configuration else {
            clearPaths()
            return
        }

        let geometry = TemperatureGraphCurveGeometryCalculator(
            pointRadius: Self.pointRadius
        ).makeGeometry(in: bounds, configuration: configuration)

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
}
