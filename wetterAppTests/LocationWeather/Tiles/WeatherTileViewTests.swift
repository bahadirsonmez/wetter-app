import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class WeatherTileViewTests: XCTestCase {

    func testConfigureDisplaysTileContent() {
        let view = makeView()

        view.configure(with: makeViewData(detailText: "North-east"))

        XCTAssertNotNil(view.symbolImageView.image)
        XCTAssertEqual(view.titleLabel.text, "Wind")
        XCTAssertEqual(view.valueLabel.text, "2.5 m/s")
        XCTAssertEqual(view.detailLabel.text, "North-east")
        XCTAssertFalse(view.detailLabel.isHidden)
    }

    func testConfigureWithoutDetailHidesDetailLabel() {
        let view = makeView()

        view.configure(with: makeViewData(detailText: nil))

        XCTAssertTrue(view.detailLabel.isHidden)
    }

    func testResetClearsDisplayedContent() {
        let view = makeView()
        view.configure(with: makeViewData(detailText: "North-east"))

        view.reset()

        XCTAssertNil(view.symbolImageView.image)
        XCTAssertNil(view.titleLabel.text)
        XCTAssertNil(view.valueLabel.text)
        XCTAssertNil(view.detailLabel.text)
        XCTAssertTrue(view.detailLabel.isHidden)
        XCTAssertNil(view.accessibilityLabel)
    }

    func testConfigureSetsAccessibilityDescription() {
        let view = makeView()

        view.configure(with: makeViewData(detailText: "North-east"))

        XCTAssertTrue(view.isAccessibilityElement)
        XCTAssertEqual(view.accessibilityLabel, "Wind, 2.5 m/s")
    }

    func testLabelsSupportDynamicType() {
        let view = makeView()

        XCTAssertTrue(view.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(view.valueLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(view.detailLabel.adjustsFontForContentSizeCategory)
    }

    func testLayoutPositionsSubviewsWithoutConstraints() {
        let view = makeView()
        view.configure(with: makeViewData(detailText: "North-east"))

        view.layoutIfNeeded()

        XCTAssertTrue(view.constraints.isEmpty)
        XCTAssertTrue(view.symbolImageView.constraints.isEmpty)
        XCTAssertTrue(view.titleLabel.constraints.isEmpty)
        XCTAssertTrue(view.valueLabel.constraints.isEmpty)
        XCTAssertTrue(view.detailLabel.constraints.isEmpty)
        XCTAssertTrue(view.bounds.contains(view.symbolImageView.frame))
        XCTAssertTrue(view.bounds.contains(view.titleLabel.frame))
        XCTAssertTrue(view.bounds.contains(view.valueLabel.frame))
        XCTAssertTrue(view.bounds.contains(view.detailLabel.frame))
        XCTAssertGreaterThanOrEqual(
            view.valueLabel.frame.minY,
            view.symbolImageView.frame.maxY
        )
        XCTAssertGreaterThanOrEqual(
            view.detailLabel.frame.minY,
            view.valueLabel.frame.maxY
        )
    }

    func testLayoutWithInsufficientBoundsClearsSubviewFrames() {
        let view = WeatherTileView(
            frame: CGRect(x: 0, y: 0, width: 20, height: 20)
        )
        view.configure(with: makeViewData(detailText: "North-east"))

        view.layoutIfNeeded()

        XCTAssertEqual(view.symbolImageView.frame, .zero)
        XCTAssertEqual(view.titleLabel.frame, .zero)
        XCTAssertEqual(view.valueLabel.frame, .zero)
        XCTAssertEqual(view.detailLabel.frame, .zero)
    }
}

// MARK: - Helpers

private extension WeatherTileViewTests {

    func makeView() -> WeatherTileView {
        WeatherTileView(
            frame: CGRect(x: 0, y: 0, width: 180, height: 180)
        )
    }

    func makeViewData(detailText: String?) -> WeatherTileViewData {
        WeatherTileViewData(
            id: .wind,
            title: "Wind",
            valueText: "2.5 m/s",
            detailText: detailText,
            symbolName: "wind"
        )
    }
}
