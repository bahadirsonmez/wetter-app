import XCTest
@testable import WeatherModel

final class MockWeatherServiceTests: XCTestCase {

    func testFetchCurrentWeatherReturnsModelDecodedFromJSON() async throws {
        let service: any WeatherFetching = MockWeatherService(
            json: WeatherModelFixtures.currentWeatherJSON
        )

        let weather = try await service.fetchCurrentWeather(
            latitude: 52.52,
            longitude: 13.405
        )

        XCTAssertEqual(weather.locationName, "Berlin")
        XCTAssertEqual(weather.coordinates.latitude, 52.52)
        XCTAssertEqual(weather.coordinates.longitude, 13.405)
    }

    func testFetchCurrentWeatherThrowsConfiguredError() async {
        let service: any WeatherFetching = MockWeatherService(
            error: .unauthorized
        )

        do {
            _ = try await service.fetchCurrentWeather(
                latitude: 52.52,
                longitude: 13.405
            )
            XCTFail("Expected unauthorized to be thrown.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .unauthorized)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    func testInvalidJSONThrowsDecodingFailed() async {
        let service: any WeatherFetching = MockWeatherService(
            json: "invalid-json"
        )

        do {
            _ = try await service.fetchCurrentWeather(
                latitude: 52.52,
                longitude: 13.405
            )
            XCTFail("Expected decodingFailed to be thrown.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .decodingFailed)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
