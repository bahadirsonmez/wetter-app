public struct CurrentWeather: Codable, Equatable, Sendable {

    public let coordinates: Coordinates
    public let conditions: [WeatherCondition]
    public let temperature: TemperatureDetails
    public let visibility: Int?
    public let wind: WindDetails
    public let clouds: CloudDetails
    public let rain: PrecipitationDetails?
    public let snow: PrecipitationDetails?
    public let timestamp: Int
    public let sun: SunDetails
    public let timezoneOffset: Int
    public let locationID: Int
    public let locationName: String

    enum CodingKeys: String, CodingKey {
        case coordinates = "coord"
        case conditions = "weather"
        case temperature = "main"
        case visibility
        case wind
        case clouds
        case rain
        case snow
        case timestamp = "dt"
        case sun = "sys"
        case timezoneOffset = "timezone"
        case locationID = "id"
        case locationName = "name"
    }
}
