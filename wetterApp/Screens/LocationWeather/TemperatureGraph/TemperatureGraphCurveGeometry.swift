import Foundation

struct TemperatureGraphCurveGeometry: Equatable {
    let leftSegment: TemperatureGraphCurveSegment?
    let currentPoint: CGPoint
    let rightSegment: TemperatureGraphCurveSegment?
}
