import XCTest
@testable import WeatherViewModel

final class HourlyForecastDayViewDataTests: XCTestCase {

    func testInitializationStoresTimestampIdentifierAndItems() {
        let item = HourlyForecastItemViewData(
            id: 1_781_179_200,
            timeText: "12:00",
            temperatureText: "24°C",
            conditionText: "Light rain",
            temperatureValue: 24.1
        )

        let viewData = HourlyForecastDayViewData(
            id: 1_781_136_000,
            title: "Thursday, Jun 11",
            items: [item]
        )

        XCTAssertEqual(viewData.id, 1_781_136_000)
        XCTAssertEqual(viewData.title, "Thursday, Jun 11")
        XCTAssertEqual(viewData.items, [item])
    }
}
