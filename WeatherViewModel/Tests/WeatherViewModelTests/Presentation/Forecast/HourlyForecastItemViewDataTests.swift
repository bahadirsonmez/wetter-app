import XCTest
@testable import WeatherViewModel

final class HourlyForecastItemViewDataTests: XCTestCase {

    func testInitializationStoresTimestampAndDisplayValues() {
        let viewData = HourlyForecastItemViewData(
            id: 1_781_179_200,
            timeText: "12:00",
            temperatureText: "24°C",
            conditionText: "Light rain",
            temperatureValue: 24.1
        )

        XCTAssertEqual(viewData.id, 1_781_179_200)
        XCTAssertEqual(viewData.timeText, "12:00")
        XCTAssertEqual(viewData.temperatureText, "24°C")
        XCTAssertEqual(viewData.conditionText, "Light rain")
        XCTAssertEqual(viewData.temperatureValue, 24.1)
    }

    func testInitializationPreservesMissingCondition() {
        let viewData = HourlyForecastItemViewData(
            id: 1_781_190_000,
            timeText: "15:00",
            temperatureText: "25°C",
            conditionText: nil,
            temperatureValue: 25
        )

        XCTAssertNil(viewData.conditionText)
    }
}
