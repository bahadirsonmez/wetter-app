import Foundation
import UIKit
import WeatherModel
import XCTest
@testable import wetterApp

@MainActor
final class AppCoordinatorTests: XCTestCase {

    func testStartPlacesLocationsInPrimaryAndCurrentWeatherInSecondary() {
        let context = makeContext()

        context.coordinator.start()

        XCTAssertTrue(
            context.primaryNavigationController.viewControllers.first
                is LocationsViewController
        )
        XCTAssertEqual(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController?.source,
            .current
        )
        XCTAssertEqual(
            context.secondaryNavigationController.viewControllers.count,
            1
        )
    }

    func testStartOpensLastViewedSavedLocationInSecondary() {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )

        context.coordinator.start()

        XCTAssertEqual(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController?.source,
            .saved(location)
        )
    }

    func testStartWithInvalidSavedLocationIDFallsBackToCurrentLocation() {
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [makeLocation(name: "Berlin")],
                lastViewedLocationID: UUID()
            )
        )

        context.coordinator.start()

        XCTAssertEqual(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController?.source,
            .current
        )
    }

    func testSelectingSavedLocationUpdatesSnapshotAndReplacesDetail() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: nil
            )
        )
        context.coordinator.start()
        let originalWeatherViewController =
            context.coordinator.activeWeatherViewController?.currentWeatherViewController
        let locationsViewController = try locationsViewController(in: context)

        locationsViewController.tableView(
            locationsViewController.tableView,
            didSelectRowAt: IndexPath(row: 1, section: 0)
        )

        XCTAssertEqual(
            context.store.snapshot.lastViewedLocationID,
            location.id
        )
        XCTAssertEqual(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController?.source,
            .saved(location)
        )
        XCTAssertFalse(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController
                === originalWeatherViewController
        )
        XCTAssertEqual(
            context.secondaryNavigationController.viewControllers.count,
            1
        )
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
        let locationsViewController = try locationsViewController(in: context)

        locationsViewController.tableView(
            locationsViewController.tableView,
            didSelectRowAt: IndexPath(row: 0, section: 0)
        )

        XCTAssertNil(context.store.snapshot.lastViewedLocationID)
        XCTAssertEqual(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController?.source,
            .current
        )
    }

    func testSwipingToSavedLocationUpdatesLastViewedLocationID() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: nil
            )
        )
        context.coordinator.start()
        let pageViewController = try XCTUnwrap(
            context.coordinator.activeWeatherViewController
        )

        pageViewController.pageControl.currentPage = 1
        pageViewController.pageControlChanged()

        XCTAssertEqual(
            context.store.snapshot.lastViewedLocationID,
            location.id
        )
    }

    func testSwipingToCurrentLocationClearsLastViewedLocationID() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )
        context.coordinator.start()
        let pageViewController = try XCTUnwrap(
            context.coordinator.activeWeatherViewController
        )

        pageViewController.pageControl.currentPage = 0
        pageViewController.pageControlChanged()

        XCTAssertNil(context.store.snapshot.lastViewedLocationID)
    }

    func testRepeatedSelectionDoesNotStackWeatherControllers() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: nil
            )
        )
        context.coordinator.start()
        let locationsViewController = try locationsViewController(in: context)

        for _ in 0..<3 {
            locationsViewController.tableView(
                locationsViewController.tableView,
                didSelectRowAt: IndexPath(row: 1, section: 0)
            )
        }

        XCTAssertEqual(
            context.secondaryNavigationController.viewControllers
                .filter { $0 is LocationWeatherPageViewController }
                .count,
            1
        )
        XCTAssertFalse(
            context.primaryNavigationController.viewControllers
                .contains { $0 is LocationWeatherPageViewController }
        )
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

        context.coordinator.activeWeatherViewController?.currentWeatherViewController?.loadViewIfNeeded()

        XCTAssertEqual(context.locationProvider.requestCallCount, 0)
    }

    func testSearchIsPushedOnPrimaryAndAdditionPreservesWeather() throws {
        let context = makeContext()
        context.coordinator.start()
        let weatherViewController =
            try XCTUnwrap(context.coordinator.activeWeatherViewController)
        let locationsViewController = try locationsViewController(in: context)

        locationsViewController.onAddLocation?()

        let searchViewController = try XCTUnwrap(
            context.primaryNavigationController.topViewController
                as? LocationSearchViewController
        )
        XCTAssertFalse(
            context.secondaryNavigationController.viewControllers
                .contains { $0 is LocationSearchViewController }
        )

        let location = makeLocation(name: "Berlin")
        context.store.snapshot = SavedLocationsSnapshot(
            locations: [location],
            lastViewedLocationID: nil
        )
        searchViewController.onLocationAdded?()

        XCTAssertTrue(
            context.primaryNavigationController.topViewController
                is LocationsViewController
        )
        XCTAssertTrue(
            context.coordinator.activeWeatherViewController
                === weatherViewController
        )
        XCTAssertEqual(
            locationsViewController.tableView.numberOfRows(inSection: 0),
            2
        )
        XCTAssertEqual(
            weatherViewController.sources.count,
            2
        )
        XCTAssertEqual(
            weatherViewController.sources.last,
            .saved(location)
        )
    }

    func testDeletingActiveSavedLocationShowsCurrentLocation() throws {
        let location = makeLocation(name: "Berlin")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [location],
                lastViewedLocationID: location.id
            )
        )
        context.coordinator.start()
        let locationsViewController = try locationsViewController(in: context)

        locationsViewController.tableView(
            locationsViewController.tableView,
            commit: .delete,
            forRowAt: IndexPath(row: 1, section: 0)
        )

        XCTAssertEqual(
            context.coordinator.activeWeatherViewController?.currentWeatherViewController?.source,
            .current
        )
    }

    func testDeletingInactiveSavedLocationPreservesDetail() throws {
        let berlin = makeLocation(name: "Berlin")
        let hamburg = makeLocation(name: "Hamburg")
        let context = makeContext(
            snapshot: SavedLocationsSnapshot(
                locations: [berlin, hamburg],
                lastViewedLocationID: berlin.id
            )
        )
        context.coordinator.start()
        let weatherViewController =
            try XCTUnwrap(context.coordinator.activeWeatherViewController)
        let locationsViewController = try locationsViewController(in: context)

        locationsViewController.tableView(
            locationsViewController.tableView,
            commit: .delete,
            forRowAt: IndexPath(row: 2, section: 0)
        )

        XCTAssertTrue(
            context.coordinator.activeWeatherViewController
                === weatherViewController
        )
        XCTAssertEqual(weatherViewController.currentWeatherViewController?.source, .saved(berlin))
    }

    func testSceneActivationRefreshesOnlyCurrentLocationWeather() {
        let currentContext = makeContext()
        currentContext.coordinator.start()
        currentContext.coordinator.activeWeatherViewController?.currentWeatherViewController?
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
        savedContext.coordinator.activeWeatherViewController?.currentWeatherViewController?
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
        let splitViewController: AppSplitViewController
        let primaryNavigationController: UINavigationController
        let secondaryNavigationController: UINavigationController
        let store: CoordinatorLocationsStore
        let locationProvider: CurrentLocationProviderSpy
    }

    func makeContext(
        snapshot: SavedLocationsSnapshot = .empty
    ) -> Context {
        let primaryNavigationController = UINavigationController()
        let secondaryNavigationController = UINavigationController()
        let splitViewController = AppSplitViewController(
            primaryNavigationController: primaryNavigationController,
            secondaryNavigationController: secondaryNavigationController
        )
        let store = CoordinatorLocationsStore(snapshot: snapshot)
        let locationProvider = CurrentLocationProviderSpy()
        let coordinator = AppCoordinator(
            splitViewController: splitViewController,
            primaryNavigationController: primaryNavigationController,
            secondaryNavigationController: secondaryNavigationController,
            weatherService: CoordinatorWeatherService(),
            locationsStore: store,
            locationSearchService: CoordinatorLocationSearchService(),
            locationProviderFactory: { locationProvider }
        )
        return Context(
            coordinator: coordinator,
            splitViewController: splitViewController,
            primaryNavigationController: primaryNavigationController,
            secondaryNavigationController: secondaryNavigationController,
            store: store,
            locationProvider: locationProvider
        )
    }

    func locationsViewController(
        in context: Context
    ) throws -> LocationsViewController {
        let viewController = try XCTUnwrap(
            context.primaryNavigationController.viewControllers.first
                as? LocationsViewController
        )
        viewController.loadViewIfNeeded()
        return viewController
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
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> CurrentWeather {
        throw NetworkError.invalidResponse
    }

    nonisolated func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
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
