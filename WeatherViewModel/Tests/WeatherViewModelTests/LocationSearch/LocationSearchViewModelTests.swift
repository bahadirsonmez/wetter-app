import Foundation
import WeatherModel
import XCTest
@testable import WeatherViewModel

@MainActor
final class LocationSearchViewModelTests: XCTestCase {

    func testShortQueryDoesNotCallService() async {
        let (viewModel, service, _) = makeSUT()

        viewModel.search(query: " B ")
        await waitForTasks()

        XCTAssertTrue(service.queries.isEmpty)
        XCTAssertEqual(viewModel.state, .idle)
    }

    func testSearchTrimsWhitespace() async {
        let (viewModel, service, _) = makeSUT()

        viewModel.search(query: "  Berlin \n")
        await waitUntil { service.queries.count == 1 }

        XCTAssertEqual(service.queries, ["Berlin"])
    }

    func testDebouncePerformsSingleSearchForLatestQuery() async {
        let (viewModel, service, _) = makeSUT(debounceNanoseconds: 20_000_000)

        viewModel.search(query: "Ber")
        viewModel.search(query: "Berlin")
        await waitUntil { service.queries.count == 1 }

        XCTAssertEqual(service.queries, ["Berlin"])
    }

    func testNewQueryCancelsPreviousTask() async {
        let cancellation = expectation(description: "Previous search cancelled")
        let service = LocationSearchingSpy { query in
            if query == "Berlin" {
                do {
                    try await Task.sleep(nanoseconds: 5_000_000_000)
                } catch {
                    cancellation.fulfill()
                    throw error
                }
            }
            return [Fixtures.hamburgResult]
        }
        let (viewModel, _, _) = makeSUT(
            service: service,
            debounceNanoseconds: 0
        )

        viewModel.search(query: "Berlin")
        await waitUntil { service.queries == ["Berlin"] }
        viewModel.search(query: "Hamburg")
        await fulfillment(of: [cancellation], timeout: 1)

        XCTAssertEqual(service.queries, ["Berlin", "Hamburg"])
    }

    func testOldSearchResultCannotOverwriteLatestState() async {
        let pendingSearches = PendingSearches()
        let service = LocationSearchingSpy { query in
            await pendingSearches.wait(for: query)
        }
        let (viewModel, _, _) = makeSUT(
            service: service,
            debounceNanoseconds: 0
        )

        viewModel.search(query: "Berlin")
        await waitUntil { service.queries == ["Berlin"] }
        viewModel.search(query: "Hamburg")
        await waitUntil {
            service.queries == ["Berlin", "Hamburg"]
        }
        await pendingSearches.resume(
            query: "Hamburg",
            with: [Fixtures.hamburgResult]
        )
        await waitUntil {
            viewModel.state == .loaded([
                LocationSearchResultViewData(
                    title: "Hamburg",
                    subtitle: "Hamburg, DE"
                )
            ])
        }
        await pendingSearches.resume(
            query: "Berlin",
            with: [Fixtures.berlinResult]
        )
        await waitForTasks()

        XCTAssertEqual(
            viewModel.state,
            .loaded([
                LocationSearchResultViewData(
                    title: "Hamburg",
                    subtitle: "Hamburg, DE"
                )
            ])
        )
    }

    func testSearchPublishesLoadingAndLoadedStates() async {
        let (viewModel, _, _) = makeSUT(
            result: .success([Fixtures.berlinResult])
        )
        var states: [LocationSearchViewState] = []
        viewModel.onStateChange = { states.append($0) }

        viewModel.search(query: "Berlin")
        await waitUntil {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }

        XCTAssertEqual(
            states,
            [
                .loading,
                .loaded([
                    LocationSearchResultViewData(
                        title: "Berlin",
                        subtitle: "Berlin, DE"
                    )
                ])
            ]
        )
    }

    func testEmptySearchResultPublishesEmptyState() async {
        let (viewModel, _, _) = makeSUT(result: .success([]))

        viewModel.search(query: "Unknown")
        await waitUntil { viewModel.state == .empty }

        XCTAssertEqual(viewModel.state, .empty)
    }

    func testSearchFailurePublishesFailedState() async {
        let (viewModel, _, _) = makeSUT(
            result: .failure(LocationSearchError.unavailable)
        )

        viewModel.search(query: "Berlin")
        await waitUntil {
            viewModel.state == .failed(.unavailable)
        }

        XCTAssertEqual(viewModel.state, .failed(.unavailable))
    }

    func testSelectingResultAppendsLocationToSnapshot() async throws {
        let generatedID = UUID()
        let (viewModel, _, store) = makeSUT(
            result: .success([Fixtures.berlinResult]),
            idGenerator: { generatedID }
        )
        var locationAddedCallCount = 0
        viewModel.onLocationAdded = {
            locationAddedCallCount += 1
        }
        viewModel.search(query: "Berlin")
        await waitForLoadedState(viewModel)

        viewModel.selectResult(at: 0)

        let location = try XCTUnwrap(store.savedSnapshots.last?.locations.last)
        XCTAssertEqual(location.id, generatedID)
        XCTAssertEqual(location.name, "Berlin")
        XCTAssertEqual(location.latitude, 52.52)
        XCTAssertEqual(location.longitude, 13.405)
        XCTAssertEqual(locationAddedCallCount, 1)
    }

    func testDuplicateResultIsNotAdded() async {
        var generatedIDCallCount = 0
        let existingLocation = SavedLocation(
            id: UUID(),
            name: "Berlin",
            state: "Berlin",
            countryCode: "DE",
            latitude: 52.5204,
            longitude: 13.405
        )
        let (viewModel, _, store) = makeSUT(
            result: .success([Fixtures.berlinResult]),
            snapshot: SavedLocationsSnapshot(
                locations: [existingLocation],
                lastViewedLocationID: nil
            ),
            idGenerator: {
                generatedIDCallCount += 1
                return UUID()
            }
        )
        var locationAddedCallCount = 0
        viewModel.onLocationAdded = {
            locationAddedCallCount += 1
        }
        viewModel.search(query: "Berlin")
        await waitForLoadedState(viewModel)

        viewModel.selectResult(at: 0)

        XCTAssertTrue(store.savedSnapshots.isEmpty)
        XCTAssertEqual(generatedIDCallCount, 0)
        XCTAssertEqual(locationAddedCallCount, 0)
    }

    func testNewLocationIsAddedAtEnd() async throws {
        let existingLocation = SavedLocation(
            id: UUID(),
            name: "Hamburg",
            state: "Hamburg",
            countryCode: "DE",
            latitude: 53.5511,
            longitude: 9.9937
        )
        let (viewModel, _, store) = makeSUT(
            result: .success([Fixtures.berlinResult]),
            snapshot: SavedLocationsSnapshot(
                locations: [existingLocation],
                lastViewedLocationID: existingLocation.id
            )
        )
        viewModel.search(query: "Berlin")
        await waitForLoadedState(viewModel)

        viewModel.selectResult(at: 0)

        let snapshot = try XCTUnwrap(store.savedSnapshots.last)
        XCTAssertEqual(snapshot.locations.map(\.name), ["Hamburg", "Berlin"])
        XCTAssertEqual(snapshot.lastViewedLocationID, existingLocation.id)
    }
}

private actor PendingSearches {

    private var continuations: [
        String: CheckedContinuation<[LocationSearchResult], Never>
    ] = [:]

    func wait(for query: String) async -> [LocationSearchResult] {
        await withCheckedContinuation { continuation in
            continuations[query] = continuation
        }
    }

    func resume(
        query: String,
        with results: [LocationSearchResult]
    ) {
        continuations.removeValue(forKey: query)?.resume(
            returning: results
        )
    }
}

// MARK: - Helpers

private extension LocationSearchViewModelTests {

    enum Fixtures {
        static let berlinResult = LocationSearchResult(
            name: "Berlin",
            state: "Berlin",
            countryCode: "DE",
            latitude: 52.52,
            longitude: 13.405
        )
        static let hamburgResult = LocationSearchResult(
            name: "Hamburg",
            state: "Hamburg",
            countryCode: "DE",
            latitude: 53.5511,
            longitude: 9.9937
        )
    }

    func makeSUT(
        service: LocationSearchingSpy? = nil,
        result: Result<[LocationSearchResult], Error> = .success([]),
        snapshot: SavedLocationsSnapshot = .empty,
        debounceNanoseconds: UInt64 = 0,
        idGenerator: @escaping () -> UUID = UUID.init
    ) -> (
        LocationSearchViewModel,
        LocationSearchingSpy,
        LocationsStoreSpy
    ) {
        let service = service ?? LocationSearchingSpy(result: result)
        let store = LocationsStoreSpy(snapshot: snapshot)
        let viewModel = LocationSearchViewModel(
            searchService: service,
            store: store,
            debounceNanoseconds: debounceNanoseconds,
            idGenerator: idGenerator
        )
        return (viewModel, service, store)
    }

    func waitForLoadedState(
        _ viewModel: LocationSearchViewModel
    ) async {
        await waitUntil {
            if case .loaded = viewModel.state {
                return true
            }
            return false
        }
    }

    func waitUntil(
        timeoutNanoseconds: UInt64 = 1_000_000_000,
        condition: @escaping @MainActor () -> Bool
    ) async {
        let start = DispatchTime.now().uptimeNanoseconds
        while !condition() {
            if DispatchTime.now().uptimeNanoseconds - start
                >= timeoutNanoseconds {
                XCTFail("Condition was not met before timeout.")
                return
            }
            await waitForTasks()
        }
    }

    func waitForTasks() async {
        try? await Task.sleep(nanoseconds: 1_000_000)
    }
}
