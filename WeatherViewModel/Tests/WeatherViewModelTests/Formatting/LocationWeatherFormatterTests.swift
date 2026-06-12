import XCTest
@testable import WeatherViewModel

final class LocationWeatherFormatterTests: XCTestCase {

    private let formatter = LocationWeatherFormatter()

    func testRoundedReturnsNearestWholeNumber() {
        XCTAssertEqual(formatter.rounded(24.4), "24")
        XCTAssertEqual(formatter.rounded(24.5), "25")
    }

    func testTemperatureReturnsRoundedCelsiusValue() {
        XCTAssertEqual(formatter.temperature(25.6), "26°C")
    }

    func testPercentageIncludesPercentSign() {
        XCTAssertEqual(formatter.percentage(64), "64%")
    }

    func testCapitalizedFirstLetterChangesOnlyFirstLetter() {
        XCTAssertEqual(
            formatter.capitalizedFirstLetter("moderate rain"),
            "Moderate rain"
        )
    }

    func testCapitalizedFirstLetterHandlesEmptyString() {
        XCTAssertEqual(formatter.capitalizedFirstLetter(""), "")
    }
}
