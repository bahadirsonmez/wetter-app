import Foundation

public struct SavedLocation: Codable, Equatable, Sendable {

    public let id: UUID
    public let name: String
    public let state: String?
    public let countryCode: String?
    public let latitude: Double
    public let longitude: Double

    public init(
        id: UUID,
        name: String,
        state: String?,
        countryCode: String?,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.state = state
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
    }
}
