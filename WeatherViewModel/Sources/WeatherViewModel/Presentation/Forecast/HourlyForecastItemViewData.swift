public struct HourlyForecastItemViewData: Equatable, Sendable {

    public let id: Int
    public let timeText: String
    public let temperatureText: String
    public let conditionText: String?
    public let temperatureValue: Double

    public init(
        id: Int,
        timeText: String,
        temperatureText: String,
        conditionText: String?,
        temperatureValue: Double
    ) {
        self.id = id
        self.timeText = timeText
        self.temperatureText = temperatureText
        self.conditionText = conditionText
        self.temperatureValue = temperatureValue
    }
}
