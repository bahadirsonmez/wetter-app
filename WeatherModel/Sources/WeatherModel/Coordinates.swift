public struct Coordinates: Codable, Equatable, Sendable {

    public let latitude: Double
    public let longitude: Double

    enum CodingKeys: String, CodingKey {
        case latitude = "lat"
        case longitude = "lon"
    }
}
