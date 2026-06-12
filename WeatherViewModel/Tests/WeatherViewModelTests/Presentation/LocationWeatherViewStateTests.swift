import XCTest
@testable import WeatherViewModel

final class LocationWeatherViewStateTests: XCTestCase {

    func testLoadedStatesWithEqualViewDataAreEqual() {
        let viewData = LocationWeatherViewData(
            locationName: "Berlin",
            countryCode: "DE",
            temperatureText: "24°",
            feelsLikeText: "Feels like 25°",
            humidityText: "64%",
            conditionText: "Moderate rain",
            conditionIconName: "10d"
        )

        XCTAssertEqual(
            LocationWeatherViewState.loaded(viewData),
            .loaded(viewData)
        )
    }

    func testFailedStatesWithEqualErrorsAreEqual() {
        XCTAssertEqual(
            LocationWeatherViewState.failed(.unavailable),
            .failed(.unavailable)
        )
    }
}
