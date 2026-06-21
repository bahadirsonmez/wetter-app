import XCTest
@testable import WeatherModel

final class ForecastResponseTests: XCTestCase {

    func testDecoding() throws {
        let response = try JSONDecoder().decode(
            ForecastResponse.self,
            from: Data(WeatherModelFixtures.forecastJSON.utf8)
        )
        let forecast = try XCTUnwrap(response.forecasts.first)

        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response.location.name, "Berlin")
        XCTAssertEqual(forecast.timestampText, "2026-06-11 12:00:00")
        XCTAssertEqual(forecast.precipitationProbability, 0.35)
        XCTAssertEqual(forecast.rain?.lastThreeHours, 0.72)
        XCTAssertEqual(forecast.period.partOfDay, "d")
    }
}
