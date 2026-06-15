public struct HourlyForecastItemViewData: Equatable, Sendable {

    public let id: Int
    public let timeText: String
    public let temperatureText: String
    public let temperatureValue: Double

    public init(
        id: Int,
        timeText: String,
        temperatureText: String,
        temperatureValue: Double
    ) {
        self.id = id
        self.timeText = timeText
        self.temperatureText = temperatureText
        self.temperatureValue = temperatureValue
    }
}
