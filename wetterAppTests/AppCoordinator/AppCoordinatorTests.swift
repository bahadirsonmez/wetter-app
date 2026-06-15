import Foundation
import UIKit
import WeatherModel
import XCTest
@testable import wetterApp

@MainActor
final class AppCoordinatorTests: XCTestCase {

    func testStartPlacesLocationsFirstAndCurrentWeatherOnTop() {
        let context = makeContext()

        context.coordinator.start()

        XCTAssertTrue(
            context.navigationController.viewControllers.first
                is LocationsViewController
        )
        let weatherViewController = context.navigationController
            .topViewController as? LocationWeatherViewController
        XCTAssertEqual(weatherViewController?.source, .current)
        XCTAssertEqual(context.navigationController.viewControllers.count, 2)
    }

    func testStartOpensLastViewedSavedLocation() {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )

        context.coordinator.start()

        let weatherViewController = context.navigationController
            .topViewController as? LocationWeatherViewController
        XCTAssertEqual(weatherViewController?.source, .saved(location))
    }

    func testStartWithInvalidSavedLocationIDFallsBackToCurrentLocation() {
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [makeLocation(name: "Berlin")],
                lastViewedLocationID: UUID()
            )
        )

        context.coordinator.start()

        let weatherViewController = context.navigationController
            .topViewController as? LocationWeatherViewController
        XCTAssertEqual(weatherViewController?.source, .current)
    }

    func testSelectingSavedLocationUpdatesSnapshotAndShowsItsWeather() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: nil
            )
        )
        context.coordinator.start()
        let locationsViewController = try XCTUnwrap(
            context.navigationController.viewControllers[0]
                as? LocationsViewController
        )
        locationsViewController.loadViewIfNeeded()

        locationsViewController.tableView(
            locationsViewController.tableView,
            didSelectRowAt: IndexPath(row: 1, section: 0)
        )

        XCTAssertEqual(
            context.store.snapshot.lastViewedLocationID,
            location.id
        )
        let weatherViewController = context.navigationController
            .topViewController as? LocationWeatherViewController
        XCTAssertEqual(weatherViewController?.source, .saved(location))
    }

    func testSelectingCurrentLocationClearsLastViewedLocationID() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )
        context.coordinator.start()
        context.navigationController.popToRootViewController(animated: false)
        let locationsViewController = try XCTUnwrap(
            context.navigationController.topViewController
                as? LocationsViewController
        )
        locationsViewController.loadViewIfNeeded()

        locationsViewController.tableView(
            locationsViewController.tableView,
            didSelectRowAt: IndexPath(row: 0, section: 0)
        )

        XCTAssertNil(context.store.snapshot.lastViewedLocationID)
        let weatherViewController = context.navigationController
            .topViewController as? LocationWeatherViewController
        XCTAssertEqual(weatherViewController?.source, .current)
    }

    func testSavedLocationDoesNotRequestCurrentLocation() {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )
        context.coordinator.start()

        context.navigationController.topViewController?.loadViewIfNeeded()

        XCTAssertEqual(context.locationProvider.requestCallCount, 0)
    }

    func testSearchResultAdditionRefreshesLocationsAndReturnsToList() throws {
        let context = makeContext()
        context.coordinator.start()
        context.navigationController.popToRootViewController(animated: false)
        let locationsViewController = try XCTUnwrap(
            context.navigationController.topViewController
                as? LocationsViewController
        )
        locationsViewController.loadViewIfNeeded()
        locationsViewController.onAddLocation?()
        let location = makeLocation(name: "Berlin")
        context.store.snapshot = SavedLocationsSnapshot(
            locations: [location],
            lastViewedLocationID: nil
        )

        let searchViewController = try XCTUnwrap(
            context.navigationController.topViewController
                as? LocationSearchViewController
        )
        searchViewController.onLocationAdded?()

        XCTAssertTrue(
            context.navigationController.topViewController
                is LocationsViewController
        )
        XCTAssertEqual(
            locationsViewController.tableView.numberOfRows(inSection: 0),
            2
        )
    }

    func testSceneActivationRefreshesOnlyCurrentLocationWeather() {
        let currentContext = makeContext()
        currentContext.coordinator.start()
        currentContext.navigationController.topViewController?
            .loadViewIfNeeded()

        currentContext.coordinator.sceneDidBecomeActive()

        XCTAssertEqual(
            currentContext.locationProvider.requestCallCount,
            2
        )

        let location = makeLocation(name: "Berlin")
        let savedContext = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )
        savedContext.coordinator.start()
        savedContext.navigationController.topViewController?
            .loadViewIfNeeded()

        savedContext.coordinator.sceneDidBecomeActive()

        XCTAssertEqual(
            savedContext.locationProvider.requestCallCount,
            0
        )
    }
}

// MARK: - Helpers

private extension AppCoordinatorTests {

    struct Context {
        let coordinator: AppCoordinator
        let navigationController: UINavigationController
        let store: CoordinatorLocationsStore
        let locationProvider: CurrentLocationProviderSpy
    }

    func makeContext(
        snapshot: SavedLocationsSnapshot = .empty
    ) -> Context {
        let navigationController = UINavigationController()
        let store = CoordinatorLocationsStore(snapshot: snapshot)
        let locationProvider = CurrentLocationProviderSpy()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            weatherService: CoordinatorWeatherService(),
            locationsStore: store,
            locationSearchService: CoordinatorLocationSearchService(),
            locationProviderFactory: { locationProvider }
        )
        return Context(
            coordinator: coordinator,
            navigationController: navigationController,
            store: store,
            locationProvider: locationProvider
        )
    }

    func makeLocation(name: String) -> SavedLocation {
        SavedLocation(
            id: UUID(),
            name: name,
            state: name,
            countryCode: "DE",
            latitude: 52.52,
            longitude: 13.405
        )
    }
}

private final class CoordinatorLocationsStore: LocationsStoring {

    var snapshot: SavedLocationsSnapshot

    init(snapshot: SavedLocationsSnapshot) {
        self.snapshot = snapshot
    }

    func loadSnapshot() -> SavedLocationsSnapshot {
        snapshot
    }

    func saveSnapshot(_ snapshot: SavedLocationsSnapshot) throws {
        self.snapshot = snapshot
    }
}

private final class CoordinatorWeatherService:
    WeatherFetching,
    @unchecked Sendable {

    nonisolated func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        throw NetworkError.invalidResponse
    }

    nonisolated func fetchForecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResponse {
        throw NetworkError.invalidResponse
    }
}

private final class CoordinatorLocationSearchService:
    LocationSearching,
    @unchecked Sendable {

    nonisolated func search(
        query: String
    ) async throws -> [LocationSearchResult] {
        []
    }
}
