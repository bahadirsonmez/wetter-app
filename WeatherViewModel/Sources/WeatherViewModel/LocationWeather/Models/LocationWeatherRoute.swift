import Foundation

/// Describes a saved weather route without exposing persistence models to the UI layer.
public struct LocationWeatherRoute: Equatable, Sendable {

    public let id: UUID
    public let name: String
    public let country: String?
    public let latitude: Double
    public let longitude: Double

    public init(
        id: UUID,
        name: String,
        country: String?,
        latitude: Double,
        longitude: Double
    ) {
        self.id = id
        self.name = name
        self.country = country
        self.latitude = latitude
        self.longitude = longitude
    }
}
