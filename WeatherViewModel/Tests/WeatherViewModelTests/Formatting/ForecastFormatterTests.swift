import XCTest
@testable import WeatherViewModel

final class ForecastFormatterTests: XCTestCase {

    private let formatter = ForecastFormatter()

    func testDayTitleUsesForecastTimezoneOffset() {
        XCTAssertEqual(
            formatter.dayTitle(
                for: 1_781_301_600,
                timezoneOffset: 7_200
            ),
            "Saturday, Jun 13"
        )
    }

    func testTimeTextUsesForecastTimezoneOffset() {
        XCTAssertEqual(
            formatter.timeText(
                for: 1_781_355_600,
                timezoneOffset: 7_200
            ),
            "15:00"
        )
    }

    func testTemperatureReturnsRoundedCelsiusValue() {
        XCTAssertEqual(formatter.temperature(24.4), "24°C")
        XCTAssertEqual(formatter.temperature(-2.6), "-3°C")
    }

    func testIsSameDayUsesForecastTimezoneOffset() {
        XCTAssertTrue(
            formatter.isSameDay(
                1_781_301_600,
                1_781_305_200,
                timezoneOffset: 7_200
            )
        )
    }
}
