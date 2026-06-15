import XCTest
@testable import WeatherViewModel

final class WeatherTileViewDataTests: XCTestCase {

    func testInitializationStoresPresentationValues() {
        let viewData = WeatherTileViewData(
            id: .wind,
            title: "Wind",
            valueText: "2.5 m/s",
            detailText: "North-east",
            symbolName: "wind"
        )

        XCTAssertEqual(viewData.id, .wind)
        XCTAssertEqual(viewData.title, "Wind")
        XCTAssertEqual(viewData.valueText, "2.5 m/s")
        XCTAssertEqual(viewData.detailText, "North-east")
        XCTAssertEqual(viewData.symbolName, "wind")
    }

    func testInitializationPreservesMissingDetailText() {
        let viewData = WeatherTileViewData(
            id: .pressure,
            title: "Pressure",
            valueText: "1015 hPa",
            detailText: nil,
            symbolName: "gauge.with.dots.needle.50percent"
        )

        XCTAssertNil(viewData.detailText)
    }
}
