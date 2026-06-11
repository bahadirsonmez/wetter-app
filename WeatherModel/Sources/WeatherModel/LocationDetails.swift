public struct LocationDetails: Codable, Equatable, Sendable {

    public let name: String
    public let localNames: [String: String]?
    public let latitude: Double
    public let longitude: Double
    public let countryCode: String
    public let state: String?

    enum CodingKeys: String, CodingKey {
        case name
        case localNames = "local_names"
        case latitude = "lat"
        case longitude = "lon"
        case countryCode = "country"
        case state
    }
}
