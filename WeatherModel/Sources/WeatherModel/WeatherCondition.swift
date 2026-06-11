public struct WeatherCondition: Codable, Equatable, Sendable {

    public let id: Int
    public let group: String
    public let description: String
    public let icon: String

    enum CodingKeys: String, CodingKey {
        case id
        case group = "main"
        case description
        case icon
    }
}
