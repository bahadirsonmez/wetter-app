import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class WeatherTileStyleTests: XCTestCase {

    func testStylesUseExpectedSymbols() {
        let identifiers: [WeatherTileIdentifier] = [
            .minimumTemperature,
            .maximumTemperature,
            .pressure,
            .wind,
            .visibility,
            .cloudCoverage,
            .sunrise,
            .sunset
        ]

        XCTAssertEqual(
            identifiers.map { WeatherTileStyle(identifier: $0).symbolName },
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

    func testStylesUseDynamicSystemColors() {
        let identifiers: [WeatherTileIdentifier] = [
            .minimumTemperature,
            .maximumTemperature,
            .pressure,
            .wind,
            .visibility,
            .cloudCoverage,
            .sunrise,
            .sunset
        ]

        for identifier in identifiers {
            let style = WeatherTileStyle(identifier: identifier)

            XCTAssertNotEqual(
                style.backgroundColor,
                .systemYellow,
                "\(identifier) must avoid low-contrast yellow backgrounds"
            )
            XCTAssertNotNil(
                style.backgroundColor.resolvedColor(
                    with: UITraitCollection(userInterfaceStyle: .dark)
                )
            )
        }
    }
}
