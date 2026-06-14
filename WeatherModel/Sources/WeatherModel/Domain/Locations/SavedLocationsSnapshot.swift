import Foundation

public struct SavedLocationsSnapshot: Codable, Equatable, Sendable {

    public let locations: [SavedLocation]
    public let lastViewedLocationID: UUID?

    public init(
        locations: [SavedLocation],
        lastViewedLocationID: UUID?
    ) {
        self.locations = locations
        self.lastViewedLocationID = lastViewedLocationID
    }

    public static let empty = SavedLocationsSnapshot(
        locations: [],
        lastViewedLocationID: nil
    )
}
