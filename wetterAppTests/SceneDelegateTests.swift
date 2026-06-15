import UIKit
import WeatherModel
import XCTest
@testable import wetterApp

@MainActor
final class SceneDelegateTests: XCTestCase {

    func testSecondSceneActivationRequestsCurrentLocationAgain() {
        let locationProvider = CurrentLocationProviderSpy()
        let navigationController = UINavigationController()
        let coordinator = AppCoordinator(
            navigationController: navigationController,
            weatherService: SceneWeatherService(),
            locationsStore: SceneLocationsStore(),
            locationSearchService: SceneLocationSearchService(),
            locationProviderFactory: { locationProvider }
        )
        coordinator.start()
        let sceneDelegate = SceneDelegate()
        sceneDelegate.coordinator = coordinator
        navigationController.topViewController?.loadViewIfNeeded()

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
