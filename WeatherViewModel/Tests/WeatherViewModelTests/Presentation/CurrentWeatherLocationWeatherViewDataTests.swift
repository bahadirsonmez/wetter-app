import XCTest
@testable import WeatherViewModel

final class CurrentWeatherLocationWeatherViewDataTests: XCTestCase {

    func testMapsCurrentWeatherIntoViewData() {
        let viewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.berlinWeather
        )

        XCTAssertEqual(viewData.locationName, "Berlin")
        XCTAssertEqual(viewData.countryCode, "DE")
        XCTAssertEqual(viewData.temperatureText, "24°C")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like 25°C")
        XCTAssertEqual(viewData.humidityText, "64%")
        XCTAssertEqual(viewData.conditionText, "Moderate rain")
        XCTAssertEqual(viewData.conditionIconName, "10d")
    }

    func testRoundsNegativeTemperatureDeterministically() {
        let viewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.negativeTemperatureWeather
        )

        XCTAssertEqual(viewData.temperatureText, "-3°C")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like -3°C")
    }

    func testPreservesMissingCountryCode() {
        let viewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.weatherWithoutCountryCode
        )

        XCTAssertNil(viewData.countryCode)
    }

    func testPreservesEmptyLocationName() {
        let viewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.weatherWithEmptyLocationName
        )

        XCTAssertEqual(viewData.locationName, "")
    }

    func testUsesNilWhenConditionsAreEmpty() {
        let viewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.weatherWithoutCondition
        )

        XCTAssertNil(viewData.conditionText)
        XCTAssertNil(viewData.conditionIconName)
    }

    func testPreservesEmptyConditionDescription() {
        let viewData = LocationWeatherViewData(
            weather:
                WeatherViewModelFixtures.weatherWithEmptyConditionDescription
        )

        XCTAssertEqual(viewData.conditionText, "")
        XCTAssertEqual(viewData.conditionIconName, "10d")
    }

    func testUsesInjectedFormatter() {
        let viewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.berlinWeather,
            formatter: StubFormatter()
        )

        XCTAssertEqual(viewData.temperatureText, "temperature")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like temperature")
        XCTAssertEqual(viewData.humidityText, "percentage")
        XCTAssertEqual(viewData.conditionText, "condition")
    }
}

private struct StubFormatter: LocationWeatherFormatting {

    func rounded(_ value: Double) -> String {
        "rounded"
    }

    func temperature(_ value: Double) -> String {
        "temperature"
    }

    func percentage(_ value: Int) -> String {
        "percentage"
    }

    func capitalizedFirstLetter(_ text: String) -> String {
        "condition"
    }
}
