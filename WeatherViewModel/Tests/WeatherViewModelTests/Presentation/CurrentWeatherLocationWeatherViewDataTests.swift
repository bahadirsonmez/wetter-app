import XCTest
@testable import WeatherViewModel

final class CurrentWeatherLocationWeatherViewDataTests: XCTestCase {

    func testMapsCurrentWeatherIntoViewData() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather()
        )

        XCTAssertEqual(viewData.locationName, "Berlin")
        XCTAssertEqual(viewData.countryCode, "DE")
        XCTAssertEqual(viewData.temperatureText, "24°C")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like 25°C")
        XCTAssertEqual(viewData.humidityText, "64%")
        XCTAssertEqual(viewData.conditionText, "Moderate rain")
        XCTAssertEqual(viewData.conditionIconName, "10d")
    }

    func testRoundsNegativeTemperatureDeterministically() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather(
                temperature: -2.6,
                feelsLikeTemperature: -2.6
            )
        )

        XCTAssertEqual(viewData.temperatureText, "-3°C")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like -3°C")
    }

    func testPreservesMissingCountryCode() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather(countryCode: nil)
        )

        XCTAssertNil(viewData.countryCode)
    }

    func testPreservesEmptyLocationName() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather(locationName: "")
        )

        XCTAssertEqual(viewData.locationName, "")
    }

    func testUsesNilWhenConditionsAreEmpty() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather(includesCondition: false)
        )

        XCTAssertNil(viewData.conditionText)
        XCTAssertNil(viewData.conditionIconName)
    }

    func testPreservesEmptyConditionDescription() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather(conditionDescription: "")
        )

        XCTAssertEqual(viewData.conditionText, "")
        XCTAssertEqual(viewData.conditionIconName, "10d")
    }

    func testUsesInjectedFormatter() throws {
        let viewData = LocationWeatherViewData(
            weather: try makeCurrentWeather(),
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
