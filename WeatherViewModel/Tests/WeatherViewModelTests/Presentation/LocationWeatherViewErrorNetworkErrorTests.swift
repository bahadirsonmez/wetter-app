import XCTest
import WeatherModel
@testable import WeatherViewModel

final class LocationWeatherViewErrorNetworkErrorTests: XCTestCase {

    func testMapsNetworkErrors() {
        let mappings: [(NetworkError, LocationWeatherViewError)] = [
            (.unauthorized, .unauthorized),
            (.decodingFailed, .invalidData),
            (.invalidURL, .unavailable),
            (.invalidResponse, .unavailable)
        ]

        for (networkError, expectedViewError) in mappings {
            XCTAssertEqual(
                LocationWeatherViewError(error: networkError),
                expectedViewError
            )
        }
    }

    func testMapsUnrecognizedErrorToUnknown() {
        XCTAssertEqual(
            LocationWeatherViewError(error: UnrecognizedError()),
            .unknown
        )
    }
}

private struct UnrecognizedError: Error {}
