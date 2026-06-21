import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class WeatherTileViewTests: XCTestCase {

    func testTileViewDisplaysTitleAndValue() {
        let view = makeView()

        view.configure(with: makeViewData(detailText: "North-east"))

        XCTAssertNotNil(view.symbolImageView.image)
        XCTAssertEqual(view.titleLabel.text, "Wind")
        XCTAssertEqual(view.valueLabel.text, "2.5 m/s")
        XCTAssertEqual(view.detailLabel.text, "North-east")
        XCTAssertFalse(view.detailLabel.isHidden)
    }

    func testConfigureAppliesIdentifierStyle() {
        let view = makeView()
        let style = WeatherTileStyle(identifier: .wind)

        view.configure(with: makeViewData(detailText: nil))

        XCTAssertEqual(view.backgroundColor, style.backgroundColor)
        XCTAssertEqual(view.symbolImageView.tintColor, style.foregroundColor)
        XCTAssertEqual(view.titleLabel.textColor, style.foregroundColor)
        XCTAssertEqual(view.valueLabel.textColor, style.foregroundColor)
        XCTAssertEqual(view.detailLabel.textColor, style.foregroundColor)
        XCTAssertEqual(view.layer.cornerRadius, 8)
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

        XCTAssertNil(view.identifier)
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

    func testConfigureStoresTileIdentifier() {
        let view = makeView()

        view.configure(with: makeViewData(detailText: nil))

        XCTAssertEqual(view.identifier, .wind)
    }

    func testTileViewSupportsDynamicType() {
        let view = makeView()

        XCTAssertTrue(view.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(view.valueLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(view.detailLabel.adjustsFontForContentSizeCategory)
    }

    func testLayoutItemUsesWidestTextForPreferredWidth() {
        let shortView = makeView()
        shortView.configure(
            with: makeViewData(
                title: "Wind",
                valueText: "2 m/s",
                detailText: nil
            )
        )
        let longView = makeView()
        longView.configure(
            with: makeViewData(
                title: "Cloud coverage",
                valueText: "100%",
                detailText: nil
            )
        )

        XCTAssertGreaterThan(
            longView.makeLayoutItem().preferredWidth,
            shortView.makeLayoutItem().preferredWidth
        )
    }

    func testLayoutItemDetailIncreasesMinimumHeight() {
        let viewWithoutDetail = makeView()
        viewWithoutDetail.configure(with: makeViewData(detailText: nil))
        let viewWithDetail = makeView()
        viewWithDetail.configure(
            with: makeViewData(detailText: "North-east")
        )

        XCTAssertGreaterThan(
            viewWithDetail.makeLayoutItem().minimumHeight,
            viewWithoutDetail.makeLayoutItem().minimumHeight
        )
    }

    func testTileViewUsesNoAutoLayoutConstraints() {
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
        XCTAssertEqual(view.symbolImageView.frame.minX, 16)
        XCTAssertEqual(view.symbolImageView.frame.minY, 16)
        XCTAssertEqual(view.titleLabel.frame.minX, 16)
        XCTAssertEqual(view.titleLabel.frame.maxY, view.bounds.maxY - 16)
        XCTAssertLessThanOrEqual(
            view.valueLabel.frame.maxY,
            view.detailLabel.frame.minY
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

    func makeViewData(
        title: String = "Wind",
        valueText: String = "2.5 m/s",
        detailText: String?
    ) -> WeatherTileViewData {
        WeatherTileViewData(
            id: .wind,
            title: title,
            valueText: valueText,
            detailText: detailText,
            symbolName: "wind"
        )
    }
}
