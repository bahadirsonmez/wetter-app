import XCTest
@testable import WeatherModel

final class CurrentWeatherTests: XCTestCase {

    func testDecoding() throws {
        let weather = try JSONDecoder().decode(
            CurrentWeather.self,
            from: Data(WeatherModelFixtures.currentWeatherJSON.utf8)
        )

        XCTAssertEqual(weather.locationName, "Berlin")
        XCTAssertEqual(weather.coordinates.latitude, 52.52)
        XCTAssertEqual(weather.temperature.feelsLike, 298.74)
        XCTAssertEqual(weather.temperature.seaLevelPressure, 1015)
        XCTAssertEqual(weather.rain?.lastHour, 3.16)
        XCTAssertEqual(weather.sun.countryCode, "DE")
    }
}
