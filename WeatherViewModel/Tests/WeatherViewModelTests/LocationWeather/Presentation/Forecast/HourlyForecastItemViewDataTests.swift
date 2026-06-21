import XCTest
@testable import WeatherViewModel

final class HourlyForecastItemViewDataTests: XCTestCase {

    func testInitializationSetsProperties() {
        let viewData = HourlyForecastItemViewData(
            id: 1,
            timeText: "15:00",
            temperatureText: "20°C",
            temperatureValue: 20
        )

        XCTAssertEqual(viewData.id, 1)
        XCTAssertEqual(viewData.timeText, "15:00")
        XCTAssertEqual(viewData.temperatureText, "20°C")
        XCTAssertEqual(viewData.temperatureValue, 20)
    }
}
