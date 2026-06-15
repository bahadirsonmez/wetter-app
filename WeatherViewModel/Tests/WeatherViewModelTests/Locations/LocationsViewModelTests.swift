import Foundation
import WeatherModel
import XCTest
@testable import WeatherViewModel

@MainActor
final class LocationsViewModelTests: XCTestCase {

    func testLoadLocationsAlwaysPlacesCurrentLocationFirst() {
        let (viewModel, _) = makeSUT(
            locations: [Fixtures.berlin, Fixtures.hamburg]
        )

        viewModel.loadLocations()

        XCTAssertEqual(
            viewModel.items.map(\.identifier),
            [
                .current,
                .saved(Fixtures.berlin.id),
                .saved(Fixtures.hamburg.id)
            ]
        )
    }

    func testCurrentLocationCannotBeDeletedOrMoved() {
        let (viewModel, store) = makeSUT(
            locations: [Fixtures.berlin, Fixtures.hamburg]
        )
        viewModel.loadLocations()

        viewModel.deleteLocation(id: UUID())
        viewModel.moveLocation(fromSavedIndex: -1, toSavedIndex: 0)

        XCTAssertTrue(store.savedSnapshots.isEmpty)
        XCTAssertFalse(viewModel.items[0].isDeletable)
        XCTAssertFalse(viewModel.items[0].isMovable)
    }

    func testDeleteSavedLocationUpdatesStore() throws {
        let (viewModel, store) = makeSUT(
            locations: [Fixtures.berlin, Fixtures.hamburg],
            lastViewedLocationID: Fixtures.berlin.id
        )
        viewModel.loadLocations()

        viewModel.deleteLocation(id: Fixtures.berlin.id)

        let savedSnapshot = try XCTUnwrap(store.savedSnapshots.last)
        XCTAssertEqual(savedSnapshot.locations, [Fixtures.hamburg])
        XCTAssertNil(savedSnapshot.lastViewedLocationID)
        XCTAssertEqual(
            viewModel.items.map(\.identifier),
            [.current, .saved(Fixtures.hamburg.id)]
        )
    }

    func testDeleteSavedLocationPublishesDeletedIdentifier() {
        let (viewModel, _) = makeSUT(
            locations: [Fixtures.berlin]
        )
        var deletedLocationID: UUID?
        viewModel.onLocationDeleted = { deletedLocationID = $0 }
        viewModel.loadLocations()

        viewModel.deleteLocation(id: Fixtures.berlin.id)

        XCTAssertEqual(deletedLocationID, Fixtures.berlin.id)
    }

    func testMoveLocationUsesSavedIndexes() throws {
        let (viewModel, store) = makeSUT(
            locations: [
                Fixtures.berlin,
                Fixtures.hamburg,
                Fixtures.munich
            ]
        )
        viewModel.loadLocations()

        viewModel.moveLocation(fromSavedIndex: 0, toSavedIndex: 2)

        XCTAssertEqual(
            try XCTUnwrap(store.savedSnapshots.last).locations,
            [Fixtures.hamburg, Fixtures.munich, Fixtures.berlin]
        )
    }

    func testSelectLocationReturnsExpectedIdentifier() {
        let (viewModel, store) = makeSUT(locations: [Fixtures.berlin])
        var selectedIdentifier: LocationsListItemIdentifier?
        viewModel.onLocationSelected = { selectedIdentifier = $0 }
        viewModel.loadLocations()

        viewModel.selectLocation(id: .saved(Fixtures.berlin.id))

        XCTAssertEqual(selectedIdentifier, .saved(Fixtures.berlin.id))
        XCTAssertEqual(
            store.savedSnapshots.last?.lastViewedLocationID,
            Fixtures.berlin.id
        )
    }

    func testSelectCurrentLocationClearsLastViewedLocationID() {
        let (viewModel, store) = makeSUT(
            locations: [Fixtures.berlin],
            lastViewedLocationID: Fixtures.berlin.id
        )
        viewModel.loadLocations()

        viewModel.selectLocation(id: .current)

        XCTAssertNil(store.savedSnapshots.last?.lastViewedLocationID)
    }

    func testSaveFailurePublishesErrorWithoutChangingItems() {
        let (viewModel, store) = makeSUT(
            locations: [Fixtures.berlin, Fixtures.hamburg]
        )
        viewModel.loadLocations()
        let originalItems = viewModel.items
        var receivedError: LocationsViewError?
        viewModel.onError = { receivedError = $0 }
        store.saveError = LocationsStoreError.encodingFailed

        viewModel.deleteLocation(id: Fixtures.berlin.id)

        XCTAssertEqual(receivedError, .persistenceFailed)
        XCTAssertEqual(viewModel.items, originalItems)
    }

    func testDeleteSaveFailureDoesNotPublishDeletedIdentifier() {
        let (viewModel, store) = makeSUT(
            locations: [Fixtures.berlin]
        )
        var deletedLocationID: UUID?
        viewModel.onLocationDeleted = { deletedLocationID = $0 }
        viewModel.loadLocations()
        store.saveError = LocationsStoreError.encodingFailed

        viewModel.deleteLocation(id: Fixtures.berlin.id)

        XCTAssertNil(deletedLocationID)
    }
}

// MARK: - Helpers

private extension LocationsViewModelTests {

    enum Fixtures {
        static let berlin = makeLocation(
            name: "Berlin",
            latitude: 52.52,
            longitude: 13.405
        )
        static let hamburg = makeLocation(
            name: "Hamburg",
            latitude: 53.5511,
            longitude: 9.9937
        )
        static let munich = makeLocation(
            name: "Munich",
            latitude: 48.1351,
            longitude: 11.582
        )

        private static func makeLocation(
            name: String,
            latitude: Double,
            longitude: Double
        ) -> SavedLocation {
            SavedLocation(
                id: UUID(),
                name: name,
                state: name,
                countryCode: "DE",
                latitude: latitude,
                longitude: longitude
            )
        }
    }

    func makeSUT(
        locations: [SavedLocation],
        lastViewedLocationID: UUID? = nil
    ) -> (LocationsViewModel, LocationsStoreSpy) {
        let store = LocationsStoreSpy(
            snapshot: SavedLocationsSnapshot(
                locations: locations,
                lastViewedLocationID: lastViewedLocationID
            )
        )
        return (LocationsViewModel(store: store), store)
    }

}
