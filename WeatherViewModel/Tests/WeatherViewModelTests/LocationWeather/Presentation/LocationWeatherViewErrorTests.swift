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
        XCTAssertEqual(
            LocationWeatherViewError.locationServicesDisabled.message,
            """
            Turn on Location Services to see weather for your current \
            location.
            """
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationPermissionRequired.message,
            """
            Allow location access in Settings to see weather for your current \
            location.
            """
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationAccessRestricted.message,
            "Location access is restricted on this device."
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationUnavailable.message,
            "Your current location could not be determined."
        )
    }

    func testTitles() {
        XCTAssertEqual(LocationWeatherViewError.unavailable.title, "Weather Unavailable")
        XCTAssertEqual(
            LocationWeatherViewError.locationServicesDisabled.title,
            "Location Services Disabled"
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationPermissionRequired.title,
            "Location Permission Required"
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationAccessRestricted.title,
            "Location Access Restricted"
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationUnavailable.title,
            "Location Unavailable"
        )
    }

    func testActions() {
        XCTAssertEqual(LocationWeatherViewError.unavailable.actionTitle, "Retry")
        XCTAssertEqual(
            LocationWeatherViewError.locationPermissionRequired.actionTitle,
            "Open Settings"
        )
        XCTAssertNil(LocationWeatherViewError.locationServicesDisabled.actionTitle)
        XCTAssertNil(LocationWeatherViewError.locationAccessRestricted.actionTitle)
        XCTAssertEqual(
            LocationWeatherViewError.locationPermissionRequired.action,
            .openSettings
        )
        XCTAssertEqual(
            LocationWeatherViewError.locationUnavailable.action,
            .retryCurrentLocation
        )
        XCTAssertEqual(
            LocationWeatherViewError.unavailable.action,
            .retryCurrentLocation
        )
        XCTAssertNil(LocationWeatherViewError.locationServicesDisabled.action)
    }
}
