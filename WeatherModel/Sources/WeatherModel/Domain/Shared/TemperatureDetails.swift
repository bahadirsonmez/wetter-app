public struct TemperatureDetails: Codable, Equatable, Sendable {

    public let temperature: Double
    public let feelsLike: Double
    public let minimumTemperature: Double
    public let maximumTemperature: Double
    public let pressure: Int
    public let humidity: Int
    public let seaLevelPressure: Int?
    public let groundLevelPressure: Int?

    enum CodingKeys: String, CodingKey {
        case temperature = "temp"
        case feelsLike = "feels_like"
        case minimumTemperature = "temp_min"
        case maximumTemperature = "temp_max"
        case pressure
        case humidity
        case seaLevelPressure = "sea_level"
        case groundLevelPressure = "grnd_level"
    }
}
