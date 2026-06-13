import XCTest
@testable import WeatherViewModel

final class LocationWeatherViewStateTests: XCTestCase {

    func testLoadedStatesWithEqualViewDataAreEqual() {
        let viewData = LocationWeatherViewData(
            locationName: "Berlin",
            countryCode: "DE",
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: "Moderate rain",
            conditionIconName: "10d",
            hourlyForecast: HourlyForecastViewData(
                days: [],
                minimumTemperature: .zero,
                maximumTemperature: .zero
            )
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
