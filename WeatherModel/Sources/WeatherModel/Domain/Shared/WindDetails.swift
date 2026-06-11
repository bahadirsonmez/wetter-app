public struct WindDetails: Codable, Equatable, Sendable {

    public let speed: Double
    public let direction: Int
    public let gust: Double?

    enum CodingKeys: String, CodingKey {
        case speed
        case direction = "deg"
        case gust
    }
}
