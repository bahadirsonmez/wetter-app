import Foundation

public struct LocationSearchResult: Equatable, Sendable {

    public let name: String
    public let state: String?
    public let countryCode: String?
    public let latitude: Double
    public let longitude: Double

    public init(
        name: String,
        state: String?,
        countryCode: String?,
        latitude: Double,
        longitude: Double
    ) {
        self.name = name
        self.state = state
        self.countryCode = countryCode
        self.latitude = latitude
        self.longitude = longitude
    }
}
