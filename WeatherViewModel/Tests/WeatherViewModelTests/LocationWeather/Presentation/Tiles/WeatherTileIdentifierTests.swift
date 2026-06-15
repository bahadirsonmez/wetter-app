import XCTest
@testable import WeatherViewModel

final class WeatherTileIdentifierTests: XCTestCase {

    func testRawValuesMatchStableTileIdentifiers() {
        XCTAssertEqual(
            WeatherTileIdentifier.minimumTemperature.rawValue,
            "minimumTemperature"
        )
        XCTAssertEqual(
            WeatherTileIdentifier.maximumTemperature.rawValue,
            "maximumTemperature"
        )
        XCTAssertEqual(WeatherTileIdentifier.pressure.rawValue, "pressure")
        XCTAssertEqual(WeatherTileIdentifier.wind.rawValue, "wind")
        XCTAssertEqual(WeatherTileIdentifier.visibility.rawValue, "visibility")
        XCTAssertEqual(
            WeatherTileIdentifier.cloudCoverage.rawValue,
            "cloudCoverage"
        )
        XCTAssertEqual(WeatherTileIdentifier.sunrise.rawValue, "sunrise")
        XCTAssertEqual(WeatherTileIdentifier.sunset.rawValue, "sunset")
    }
}
