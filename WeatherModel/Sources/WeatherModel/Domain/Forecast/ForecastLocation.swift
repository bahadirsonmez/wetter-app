public struct ForecastLocation: Codable, Equatable, Sendable {

    public let id: Int
    public let name: String
    public let coordinates: Coordinates
    public let countryCode: String
    public let population: Int?
    public let timezoneOffset: Int
    public let sunriseTime: Int
    public let sunsetTime: Int

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case coordinates = "coord"
        case countryCode = "country"
        case population
        case timezoneOffset = "timezone"
        case sunriseTime = "sunrise"
        case sunsetTime = "sunset"
    }
}
