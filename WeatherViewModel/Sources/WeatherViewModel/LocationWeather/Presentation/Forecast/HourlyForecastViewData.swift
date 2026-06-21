public struct HourlyForecastViewData: Equatable, Sendable {

    public let days: [HourlyForecastDayViewData]
    public let minimumTemperature: Double
    public let maximumTemperature: Double

    public init(
        days: [HourlyForecastDayViewData],
        minimumTemperature: Double,
        maximumTemperature: Double
    ) {
        self.days = days
        self.minimumTemperature = minimumTemperature
        self.maximumTemperature = maximumTemperature
    }
}
