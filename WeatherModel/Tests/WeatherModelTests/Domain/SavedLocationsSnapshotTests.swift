import Foundation
import XCTest
@testable import WeatherModel

final class SavedLocationsSnapshotTests: XCTestCase {

    func testEmptySnapshotRepresentsCurrentLocationSelection() {
        XCTAssertTrue(SavedLocationsSnapshot.empty.locations.isEmpty)
        XCTAssertNil(SavedLocationsSnapshot.empty.lastViewedLocationID)
    }

    func testSnapshotRoundTripPreservesValues() throws {
        let locationID = UUID()
        let snapshot = SavedLocationsSnapshot(
            locations: [
                SavedLocation(
                    id: locationID,
                    name: "Berlin",
                    state: "Berlin",
                    countryCode: "DE",
                    latitude: 52.52,
                    longitude: 13.405
                )
            ],
            lastViewedLocationID: locationID
        )

        let data = try JSONEncoder().encode(snapshot)
        let decodedSnapshot = try JSONDecoder().decode(
            SavedLocationsSnapshot.self,
            from: data
        )

        XCTAssertEqual(decodedSnapshot, snapshot)
    }
}
