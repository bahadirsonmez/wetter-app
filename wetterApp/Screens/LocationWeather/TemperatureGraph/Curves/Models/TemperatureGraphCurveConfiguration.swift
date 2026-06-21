import Foundation

struct TemperatureGraphCurveConfiguration: Equatable {
    let currentTemperature: Double
    let previous2Temperature: Double?
    let previousTemperature: Double?
    let nextTemperature: Double?
    let next2Temperature: Double?
    let minimumTemperature: Double
    let maximumTemperature: Double
}
