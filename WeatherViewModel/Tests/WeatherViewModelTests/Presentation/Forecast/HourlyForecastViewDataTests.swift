import XCTest
@testable import WeatherViewModel

final class HourlyForecastViewDataTests: XCTestCase {

    func testInitializationStoresDaysAndTemperatureRange() {
        let item = HourlyForecastItemViewData(
            id: 1_781_179_200,
            timeText: "12:00",
            temperatureText: "24°C",
            conditionText: "Light rain",
            temperatureValue: 24.1
        )
        let day = HourlyForecastDayViewData(
            id: 1_781_136_000,
            title: "Thursday, Jun 11",
            items: [item]
        )

        let viewData = HourlyForecastViewData(
            days: [day],
            minimumTemperature: 18.4,
            maximumTemperature: 26.2
        )

        XCTAssertEqual(viewData.days, [day])
        XCTAssertEqual(viewData.minimumTemperature, 18.4)
        XCTAssertEqual(viewData.maximumTemperature, 26.2)
    }
}
