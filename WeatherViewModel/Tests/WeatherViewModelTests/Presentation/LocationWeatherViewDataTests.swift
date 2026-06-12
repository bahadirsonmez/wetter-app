import XCTest
@testable import WeatherViewModel

final class LocationWeatherViewDataTests: XCTestCase {

    func testInitializationStoresFormattedValues() {
        let viewData = LocationWeatherViewData(
            locationName: "Berlin",
            countryCode: "DE",
            temperatureText: "24°",
            feelsLikeText: "Feels like 25°",
            humidityText: "64%",
            conditionText: "Moderate rain",
            conditionIconName: "10d"
        )

        XCTAssertEqual(viewData.locationName, "Berlin")
        XCTAssertEqual(viewData.countryCode, "DE")
        XCTAssertEqual(viewData.temperatureText, "24°")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like 25°")
        XCTAssertEqual(viewData.humidityText, "64%")
        XCTAssertEqual(viewData.conditionText, "Moderate rain")
        XCTAssertEqual(viewData.conditionIconName, "10d")
    }
}
