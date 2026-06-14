import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class HourlyForecastCellTests: XCTestCase {

    func testConfigureDisplaysForecastContent() {
        let cell = makeCell()

        cell.configure(
            with: makeViewData(),
            previousTemperature: nil,
            nextTemperature: 22,
            minimumTemperature: 10,
            maximumTemperature: 30
        )

        XCTAssertEqual(cell.timeLabel.text, "15:00")
        XCTAssertEqual(cell.temperatureLabel.text, "20°C")
    }



    func testConfigurePassesGraphTemperaturesToLineView() {
        let cell = makeCell()

        cell.configure(
            with: makeViewData(),
            previousTemperature: 18,
            nextTemperature: 22,
            minimumTemperature: 10,
            maximumTemperature: 30
        )

        XCTAssertEqual(
            cell.temperatureGraphCurveView.configuration,
            .init(
                currentTemperature: 20,
                previousTemperature: 18,
                nextTemperature: 22,
                minimumTemperature: 10,
                maximumTemperature: 30
            )
        )
    }

    func testPrepareForReuseClearsContentAndGraph() {
        let cell = makeCell()
        cell.configure(
            with: makeViewData(),
            previousTemperature: 18,
            nextTemperature: 22,
            minimumTemperature: 10,
            maximumTemperature: 30
        )

        cell.prepareForReuse()

        XCTAssertNil(cell.timeLabel.text)
        XCTAssertNil(cell.temperatureLabel.text)
        XCTAssertNil(cell.temperatureGraphCurveView.configuration)
        XCTAssertNil(cell.accessibilityLabel)
    }
}

// MARK: - Helpers

private extension HourlyForecastCellTests {

    func makeCell() -> HourlyForecastCell {
        HourlyForecastCell(
            frame: CGRect(x: 0, y: 0, width: 80, height: 144)
        )
    }

    func makeViewData() -> HourlyForecastItemViewData {
        HourlyForecastItemViewData(
            id: 1_749_827_600,
            timeText: "15:00",
            temperatureText: "20°C",
            temperatureValue: 20
        )
    }
}
