import XCTest
@testable import WeatherViewModel

final class WeatherTileFormatterTests: XCTestCase {

    private let formatter = WeatherTileFormatter(
        locale: Locale(identifier: "en_US_POSIX")
    )

    func testTemperatureReturnsRoundedCelsiusValue() {
        XCTAssertEqual(formatter.temperature(24.6), "25°C")
        XCTAssertEqual(formatter.temperature(-2.6), "-3°C")
    }

    func testPressureIncludesHectopascalUnit() {
        XCTAssertEqual(formatter.pressure(1_015), "1015 hPa")
    }

    func testWindSpeedUsesInjectedLocaleAndUnit() {
        XCTAssertEqual(formatter.windSpeed(2.5), "2.5 m/s")
    }

    func testVisibilityConvertsMetersToKilometers() {
        XCTAssertEqual(formatter.visibility(10_000), "10 km")
        XCTAssertEqual(formatter.visibility(10_500), "10.5 km")
    }

    func testPercentageIncludesPercentSign() {
        XCTAssertEqual(formatter.percentage(75), "75%")
    }

    func testTimeUsesLocationTimezoneOffset() {
        XCTAssertEqual(
            formatter.time(
                timestamp: 1_781_321_640,
                timezoneOffset: 7_200
            ),
            "05:34"
        )
    }

    func testDecimalFormattingUsesInjectedLocale() {
        let formatter = WeatherTileFormatter(
            locale: Locale(identifier: "de_DE")
        )

        XCTAssertEqual(formatter.windSpeed(2.5), "2,5 m/s")
    }
}
