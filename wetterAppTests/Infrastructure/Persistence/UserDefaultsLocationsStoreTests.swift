import Foundation
import WeatherModel
import XCTest
@testable import wetterApp

final class UserDefaultsLocationsStoreTests: XCTestCase {

    private var suiteName: String!
    private var userDefaults: UserDefaults!
    private var store: UserDefaultsLocationsStore!

    override func setUp() {
        super.setUp()

        suiteName = "UserDefaultsLocationsStoreTests.\(UUID().uuidString)"
        userDefaults = UserDefaults(suiteName: suiteName)
        userDefaults.removePersistentDomain(forName: suiteName)
        store = UserDefaultsLocationsStore(userDefaults: userDefaults)
    }

    override func tearDown() {
        userDefaults.removePersistentDomain(forName: suiteName)
        store = nil
        userDefaults = nil
        suiteName = nil

        super.tearDown()
    }

    func testEmptyUserDefaultsReturnsEmptySnapshot() {
        XCTAssertEqual(store.loadSnapshot(), .empty)
    }

    func testSavedLocationsCanBeLoadedAgain() throws {
        let snapshot = makeSnapshot()

        try store.saveSnapshot(snapshot)

        XCTAssertEqual(store.loadSnapshot(), snapshot)
    }

    func testLocationOrderIsPreserved() throws {
        let firstLocation = makeLocation(
            id: UUID(),
            name: "Berlin",
            latitude: 52.52,
            longitude: 13.405
        )
        let secondLocation = makeLocation(
            id: UUID(),
            name: "Hamburg",
            latitude: 53.5511,
            longitude: 9.9937
        )
        let snapshot = SavedLocationsSnapshot(
            locations: [secondLocation, firstLocation],
            lastViewedLocationID: nil
        )

        try store.saveSnapshot(snapshot)

        XCTAssertEqual(
            store.loadSnapshot().locations.map(\.id),
            [secondLocation.id, firstLocation.id]
        )
    }

    func testLastViewedLocationIDIsPreserved() throws {
        let snapshot = makeSnapshot()

        try store.saveSnapshot(snapshot)

        XCTAssertEqual(
            store.loadSnapshot().lastViewedLocationID,
            snapshot.lastViewedLocationID
        )
    }

    func testCorruptedDataReturnsEmptySnapshot() {
        userDefaults.set(
            Data("not-valid-json".utf8),
            forKey: "com.bahadirovski.wetterApp.savedLocations.v1"
        )

        XCTAssertEqual(store.loadSnapshot(), .empty)
    }

    func testEncodingFailureIsExposed() {
        let invalidLocation = makeLocation(
            id: UUID(),
            name: "Invalid",
            latitude: .nan,
            longitude: 13.405
        )
        let snapshot = SavedLocationsSnapshot(
            locations: [invalidLocation],
            lastViewedLocationID: invalidLocation.id
        )

        XCTAssertThrowsError(
            try store.saveSnapshot(snapshot)
        ) { error in
            XCTAssertEqual(
                error as? LocationsStoreError,
                .encodingFailed
            )
        }
    }
}

// MARK: - Helpers

private extension UserDefaultsLocationsStoreTests {

    func makeSnapshot() -> SavedLocationsSnapshot {
        let location = makeLocation(
            id: UUID(),
            name: "Berlin",
            latitude: 52.52,
            longitude: 13.405
        )

        return SavedLocationsSnapshot(
            locations: [location],
            lastViewedLocationID: location.id
        )
    }

    func makeLocation(
        id: UUID,
        name: String,
        latitude: Double,
        longitude: Double
    ) -> SavedLocation {
        SavedLocation(
            id: id,
            name: name,
            state: nil,
            countryCode: "DE",
            latitude: latitude,
            longitude: longitude
        )
    }
}
