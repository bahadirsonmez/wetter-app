import XCTest
@testable import WeatherViewModel

final class LocationWeatherViewErrorTests: XCTestCase {

    func testMessages() {
        XCTAssertEqual(
            LocationWeatherViewError.unauthorized.message,
            "Weather service authorization failed."
        )
        XCTAssertEqual(
            LocationWeatherViewError.unavailable.message,
            "Weather information is currently unavailable."
        )
        XCTAssertEqual(
            LocationWeatherViewError.invalidData.message,
            "Weather information could not be processed."
        )
        XCTAssertEqual(
            LocationWeatherViewError.unknown.message,
            "Something went wrong."
        )
    }
}
