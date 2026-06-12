import CoreLocation
import XCTest
import WeatherViewModel
@testable import wetterApp

@MainActor
final class LocationWeatherViewControllerTests: XCTestCase {

    func testViewUsesSystemBackgroundColor() {
        let viewController = LocationWeatherViewController(
            viewModel: LocationWeatherViewModelSpy(),
            locationProvider: CurrentLocationProviderSpy()
        )

        viewController.loadViewIfNeeded()

        XCTAssertEqual(viewController.view.backgroundColor, .systemBackground)
    }
}

@MainActor
private final class CurrentLocationProviderSpy: CurrentLocationProviding {

    var onLocationResult: (
        (Result<CLLocationCoordinate2D, CurrentLocationError>) -> Void
    )?

    func requestCurrentLocation() {}
}

@MainActor
private final class LocationWeatherViewModelSpy:
    LocationWeatherViewModeling {

    private(set) var state: LocationWeatherViewState = .idle
    var onStateChange: ((LocationWeatherViewState) -> Void)?

    func loadWeather(latitude: Double, longitude: Double) {}

    func refresh() {}
}
