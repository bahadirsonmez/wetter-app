import UIKit
import WeatherModel
import XCTest
@testable import wetterApp

@MainActor
final class SceneDelegateTests: XCTestCase {

    func testRootControllerIsAppSplitViewController() {
        let sceneDelegate = SceneDelegate()

        let rootViewController = sceneDelegate.makeRootViewController()

        XCTAssertTrue(
            rootViewController.viewController(for: .primary)
                === rootViewController.primaryNavigationController
        )
        XCTAssertTrue(
            rootViewController.viewController(for: .secondary)
                === rootViewController.secondaryNavigationController
        )
    }

    func testSecondSceneActivationRequestsCurrentLocationAgain() {
        let locationProvider = CurrentLocationProviderSpy()
        let primaryNavigationController = UINavigationController()
        let secondaryNavigationController = UINavigationController()
        let splitViewController = AppSplitViewController(
            primaryNavigationController: primaryNavigationController,
            secondaryNavigationController: secondaryNavigationController
        )
        let coordinator = AppCoordinator(
            splitViewController: splitViewController,
            primaryNavigationController: primaryNavigationController,
            secondaryNavigationController: secondaryNavigationController,
            weatherService: SceneWeatherService(),
            locationsStore: SceneLocationsStore(),
            locationSearchService: SceneLocationSearchService(),
            locationProviderFactory: { locationProvider }
        )
        coordinator.start()
        let sceneDelegate = SceneDelegate()
        sceneDelegate.coordinator = coordinator
        coordinator.activeWeatherViewController?.currentWeatherViewController?.loadViewIfNeeded()

        sceneDelegate.handleSceneDidBecomeActive()
        XCTAssertEqual(locationProvider.requestCallCount, 1)

        sceneDelegate.handleSceneDidBecomeActive()
        XCTAssertEqual(locationProvider.requestCallCount, 2)
    }
}

private final class SceneLocationsStore: LocationsStoring {

    private var snapshot = SavedLocationsSnapshot.empty

    func loadSnapshot() -> SavedLocationsSnapshot {
        snapshot
    }

    func saveSnapshot(_ snapshot: SavedLocationsSnapshot) throws {
        self.snapshot = snapshot
    }
}

private final class SceneWeatherService:
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

private final class SceneLocationSearchService:
    LocationSearching,
    @unchecked Sendable {

    nonisolated func search(
        query: String
    ) async throws -> [LocationSearchResult] {
        []
    }
}
