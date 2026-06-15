import XCTest
@testable import wetterApp

final class AppConfigurationTests: XCTestCase {

    func testOpenWeatherAPIKeyUsesConfiguredValue() throws {
        let configuration = try AppConfiguration(
            infoDictionary: [
                "OPEN_WEATHER_API_KEY": " test-api-key "
            ]
        )

        XCTAssertEqual(configuration.openWeatherAPIKey, "test-api-key")
    }

    func testMissingOpenWeatherAPIKeyThrowsConfigurationError() {
        XCTAssertThrowsError(
            try AppConfiguration(infoDictionary: [:])
        ) { error in
            XCTAssertEqual(
                error as? AppConfigurationError,
                .missingOpenWeatherAPIKey
            )
        }
    }

    func testUnresolvedOpenWeatherAPIKeyThrowsConfigurationError() {
        XCTAssertThrowsError(
            try AppConfiguration(
                infoDictionary: [
                    "OPEN_WEATHER_API_KEY": "$(OPEN_WEATHER_API_KEY)"
                ]
            )
        ) { error in
            XCTAssertEqual(
                error as? AppConfigurationError,
                .missingOpenWeatherAPIKey
            )
        }
    }
}
