public struct SunDetails: Codable, Equatable, Sendable {

    public let countryCode: String?
    public let sunriseTime: Int
    public let sunsetTime: Int

    enum CodingKeys: String, CodingKey {
        case countryCode = "country"
        case sunriseTime = "sunrise"
        case sunsetTime = "sunset"
    }
}
