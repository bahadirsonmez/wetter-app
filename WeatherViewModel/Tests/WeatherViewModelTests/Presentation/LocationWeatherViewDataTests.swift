import XCTest
@testable import WeatherViewModel

final class LocationWeatherViewDataTests: XCTestCase {

    func testInitializationStoresFormattedValues() {
        let viewData = LocationWeatherViewData(
            locationName: "Berlin",
            countryCode: "DE",
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: "Moderate rain",
            conditionIconName: "10d",
            hourlyForecast: emptyForecast,
            tiles: [minimumTemperatureTile]
        )

        XCTAssertEqual(viewData.locationName, "Berlin")
        XCTAssertEqual(viewData.countryCode, "DE")
        XCTAssertEqual(viewData.temperatureText, "24°C")
        XCTAssertEqual(viewData.feelsLikeText, "Feels like 25°C")
        XCTAssertEqual(viewData.humidityText, "64%")
        XCTAssertEqual(viewData.conditionText, "Moderate rain")
        XCTAssertEqual(viewData.conditionIconName, "10d")
        XCTAssertEqual(viewData.hourlyForecast, emptyForecast)
        XCTAssertEqual(viewData.tiles, [minimumTemperatureTile])
    }

    func testInitializationStoresMissingOptionalValues() {
        let viewData = LocationWeatherViewData(
            locationName: "Berlin",
            countryCode: nil,
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: nil,
            conditionIconName: nil,
            hourlyForecast: emptyForecast,
            tiles: []
        )

        XCTAssertNil(viewData.countryCode)
        XCTAssertNil(viewData.conditionText)
        XCTAssertNil(viewData.conditionIconName)
    }

    private var emptyForecast: HourlyForecastViewData {
        HourlyForecastViewData(
            days: [],
            minimumTemperature: .zero,
            maximumTemperature: .zero
        )
    }

    private var minimumTemperatureTile: WeatherTileViewData {
        WeatherTileViewData(
            id: .minimumTemperature,
            title: "Minimum",
            valueText: "23°C",
            detailText: nil,
            symbolName: "thermometer.low"
        )
    }
}
