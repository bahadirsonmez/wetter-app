import Foundation
import XCTest
@testable import WeatherViewModel

final class WeatherTileViewDataMapperTests: XCTestCase {

    private let mapper = WeatherTileViewDataMapper(
        formatter: WeatherTileFormatter(
            locale: Locale(identifier: "en_US_POSIX")
        )
    )

    func testMapCreatesTilesInExpectedOrder() {
        let tiles = mapper.map(
            WeatherViewModelFixtures.berlinWeather
        )

        XCTAssertEqual(
            tiles.map(\.id),
            [
                .minimumTemperature,
                .maximumTemperature,
                .pressure,
                .wind,
                .visibility,
                .cloudCoverage,
                .sunrise,
                .sunset
            ]
        )
    }

    func testMapCreatesFormattedTileContent() {
        let tiles = mapper.map(
            WeatherViewModelFixtures.berlinWeather
        )

        XCTAssertEqual(
            tiles.map(\.title),
            [
                "Minimum",
                "Maximum",
                "Pressure",
                "Wind",
                "Visibility",
                "Cloud cover",
                "Sunrise",
                "Sunset"
            ]
        )
        XCTAssertEqual(
            tiles.map(\.valueText),
            [
                "23°C",
                "25°C",
                "1015 hPa",
                "2.5 m/s",
                "10 km",
                "75%",
                "03:14",
                "18:27"
            ]
        )
        XCTAssertTrue(tiles.allSatisfy { $0.detailText == nil })
    }

    func testMapUsesExpectedSymbolNames() {
        let tiles = mapper.map(
            WeatherViewModelFixtures.berlinWeather
        )

        XCTAssertEqual(
            tiles.map(\.symbolName),
            [
                "thermometer",
                "thermometer",
                "gauge",
                "wind",
                "eye",
                "cloud",
                "sunrise",
                "sunset"
            ]
        )
    }

    func testMapWithoutVisibilityOmitsOnlyVisibilityTile() {
        let tiles = mapper.map(
            WeatherViewModelFixtures.weather(visibility: nil)
        )

        XCTAssertEqual(
            tiles.map(\.id),
            [
                .minimumTemperature,
                .maximumTemperature,
                .pressure,
                .wind,
                .cloudCoverage,
                .sunrise,
                .sunset
            ]
        )
    }

    func testMapUsesInjectedFormatter() {
        let tiles = WeatherTileViewDataMapper(
            formatter: WeatherTileFormattingStub()
        ).map(WeatherViewModelFixtures.berlinWeather)

        XCTAssertEqual(
            tiles.map(\.valueText),
            [
                "temperature:23.0",
                "temperature:25.0",
                "pressure:1015",
                "wind:2.5",
                "visibility:10000",
                "percentage:75",
                "time:1781140440:7200",
                "time:1781195220:7200"
            ]
        )
    }
}

private struct WeatherTileFormattingStub: WeatherTileFormatting {

    func temperature(_ value: Double) -> String {
        "temperature:\(value)"
    }

    func pressure(_ value: Int) -> String {
        "pressure:\(value)"
    }

    func windSpeed(_ value: Double) -> String {
        "wind:\(value)"
    }

    func visibility(_ value: Int) -> String {
        "visibility:\(value)"
    }

    func percentage(_ value: Int) -> String {
        "percentage:\(value)"
    }

    func time(timestamp: Int, timezoneOffset: Int) -> String {
        "time:\(timestamp):\(timezoneOffset)"
    }
}
