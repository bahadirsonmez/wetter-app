import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class HourlyForecastCellTests: XCTestCase {

    func testConfigureDisplaysForecastContent() {
        let cell = makeCell()

        cell.configure(
            with: makeViewData(conditionText: "Moderate rain"),
            previousTemperature: 18,
            nextTemperature: 22,
            minimumTemperature: 10,
            maximumTemperature: 30
        )

        XCTAssertEqual(cell.timeLabel.text, "15:00")
        XCTAssertEqual(cell.temperatureLabel.text, "20°C")
        XCTAssertEqual(cell.conditionLabel.text, "Moderate rain")
        XCTAssertFalse(cell.conditionLabel.isHidden)
    }

    func testConfigureWithoutConditionHidesConditionLabel() {
        let cell = makeCell()

        cell.configure(
            with: makeViewData(conditionText: nil),
            previousTemperature: nil,
            nextTemperature: nil,
            minimumTemperature: 20,
            maximumTemperature: 20
        )

        XCTAssertTrue(cell.conditionLabel.isHidden)
    }

    func testConfigurePassesGraphTemperaturesToLineView() {
        let cell = makeCell()

        cell.configure(
            with: makeViewData(conditionText: nil),
            previousTemperature: 18,
            nextTemperature: 22,
            minimumTemperature: 10,
            maximumTemperature: 30
        )

        XCTAssertEqual(
            cell.temperatureGraphLineView.configuration,
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
            with: makeViewData(conditionText: "Moderate rain"),
            previousTemperature: 18,
            nextTemperature: 22,
            minimumTemperature: 10,
            maximumTemperature: 30
        )

        cell.prepareForReuse()

        XCTAssertNil(cell.timeLabel.text)
        XCTAssertNil(cell.temperatureLabel.text)
        XCTAssertNil(cell.conditionLabel.text)
        XCTAssertNil(cell.temperatureGraphLineView.configuration)
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

    func makeViewData(
        conditionText: String?
    ) -> HourlyForecastItemViewData {
        HourlyForecastItemViewData(
            id: 1_749_827_600,
            timeText: "15:00",
            temperatureText: "20°C",
            conditionText: conditionText,
            temperatureValue: 20
        )
    }
}
