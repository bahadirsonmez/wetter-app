public struct HourlyForecast: Codable, Equatable, Sendable {

    public let timestamp: Int
    public let temperature: TemperatureDetails
    public let conditions: [WeatherCondition]
    public let clouds: CloudDetails
    public let wind: WindDetails
    public let visibility: Int?
    public let precipitationProbability: Double
    public let rain: PrecipitationDetails?
    public let snow: PrecipitationDetails?
    public let period: ForecastPeriodDetails
    public let timestampText: String

    enum CodingKeys: String, CodingKey {
        case timestamp = "dt"
        case temperature = "main"
        case conditions = "weather"
        case clouds
        case wind
        case visibility
        case precipitationProbability = "pop"
        case rain
        case snow
        case period = "sys"
        case timestampText = "dt_txt"
    }
}
