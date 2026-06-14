import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class WeatherTilesViewTests: XCTestCase {

    func testConfigureCreatesRequiredTileViews() {
        let view = makeView(size: CGSize(width: 900, height: 600))

        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()

        XCTAssertEqual(tileViews(in: view).count, 8)
        XCTAssertEqual(
            tileViews(in: view).filter { !$0.isHidden }.count,
            8
        )
    }

    func testConfigureReusesExistingTileViews() {
        let view = makeView(size: CGSize(width: 900, height: 600))
        view.configure(with: makeTiles(count: 4))
        let initialViews = tileViews(in: view)

        view.configure(with: makeTiles(count: 4, valuePrefix: "Updated"))

        XCTAssertEqual(tileViews(in: view).count, 4)
        XCTAssertTrue(
            zip(initialViews, tileViews(in: view)).allSatisfy { first, second in
                first === second
            }
        )
        XCTAssertEqual(initialViews[0].valueLabel.text, "Updated 0")
    }

    func testConfigureWithSameDataDoesNotCreateSubviews() {
        let view = makeView(size: CGSize(width: 900, height: 600))
        let tiles = makeTiles(count: 4)
        view.configure(with: tiles)
        let existingSubviews = view.subviews

        view.configure(with: tiles)

        XCTAssertEqual(view.subviews.count, existingSubviews.count)
        XCTAssertTrue(
            zip(existingSubviews, view.subviews).allSatisfy { first, second in
                first === second
            }
        )
    }

    func testConfigureHidesItemsThatDoNotFitViewport() {
        let view = makeView(size: CGSize(width: 220, height: 180))

        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()

        let visibleCount = tileViews(in: view).filter { !$0.isHidden }.count

        XCTAssertGreaterThan(visibleCount, 0)
        XCTAssertLessThan(visibleCount, 8)
    }

    func testLargerBoundsDoNotReduceVisibleTileCount() {
        let view = makeView(size: CGSize(width: 220, height: 180))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let compactVisibleCount = visibleTileViews(in: view).count

        view.frame.size = CGSize(width: 900, height: 600)
        view.setNeedsLayout()
        view.layoutIfNeeded()

        XCTAssertGreaterThanOrEqual(
            visibleTileViews(in: view).count,
            compactVisibleCount
        )
    }

    func testLongerTextProducesWiderTileInSameRow() {
        let view = makeView(size: CGSize(width: 500, height: 180))
        view.configure(
            with: [
                makeTile(title: "Wind", valueText: "2 m/s"),
                makeTile(
                    title: "Cloud coverage",
                    valueText: "100%"
                )
            ]
        )

        view.layoutIfNeeded()

        XCTAssertGreaterThan(
            visibleTileViews(in: view)[1].frame.width,
            visibleTileViews(in: view)[0].frame.width
        )
    }

    func testMinimumRequiredHeightFitsOneTileRow() {
        let view = makeView(size: CGSize(width: 390, height: 400))
        view.configure(with: makeTiles(count: 4))

        let minimumHeight = view.minimumRequiredHeight(
            for: 390,
            contentSizeCategory: .large
        )

        view.frame.size.height = minimumHeight
        view.setNeedsLayout()
        view.layoutIfNeeded()

        XCTAssertGreaterThan(minimumHeight, 0)
        XCTAssertGreaterThan(visibleTileViews(in: view).count, 0)
    }

    func testAccessibilityCategoryIncreasesMinimumRequiredHeight() {
        let view = makeView(size: CGSize(width: 390, height: 400))
        view.configure(with: makeTiles(count: 4))

        let regularHeight = view.minimumRequiredHeight(
            for: 390,
            contentSizeCategory: .large
        )
        let accessibilityHeight = view.minimumRequiredHeight(
            for: 390,
            contentSizeCategory: .accessibilityExtraExtraExtraLarge
        )

        XCTAssertGreaterThan(accessibilityHeight, regularHeight)
    }

    func testMinimumRequiredHeightWithoutTilesIsZero() {
        let view = makeView(size: CGSize(width: 390, height: 400))

        XCTAssertEqual(
            view.minimumRequiredHeight(
                for: 390,
                contentSizeCategory: .large
            ),
            .zero
        )
    }

    func testResetHidesAndReusesTileViews() {
        let view = makeView(size: CGSize(width: 900, height: 600))
        view.configure(with: makeTiles(count: 4))
        let existingViews = tileViews(in: view)

        view.reset()
        view.configure(with: makeTiles(count: 2, valuePrefix: "New"))
        view.layoutIfNeeded()

        XCTAssertEqual(tileViews(in: view).count, 4)
        XCTAssertTrue(tileViews(in: view)[0] === existingViews[0])
        XCTAssertTrue(tileViews(in: view)[1] === existingViews[1])
        XCTAssertEqual(visibleTileViews(in: view).count, 2)
    }

    func testViewUsesOnlyManualSubviewLayout() {
        let view = makeView(size: CGSize(width: 390, height: 400))
        view.configure(with: makeTiles(count: 4))

        XCTAssertTrue(view.constraints.isEmpty)
        XCTAssertTrue(view.translatesAutoresizingMaskIntoConstraints)
        XCTAssertFalse(view.subviews.contains { $0 is UIStackView })
        XCTAssertFalse(view.subviews.contains { $0 is UICollectionView })
        XCTAssertFalse(view.subviews.contains { $0 is UITableView })
    }
}

// MARK: - Helpers

private extension WeatherTilesViewTests {

    func makeView(size: CGSize) -> WeatherTilesView {
        WeatherTilesView(
            frame: CGRect(origin: .zero, size: size)
        )
    }

    func tileViews(in view: WeatherTilesView) -> [WeatherTileView] {
        view.subviews.compactMap { $0 as? WeatherTileView }
    }

    func visibleTileViews(in view: WeatherTilesView) -> [WeatherTileView] {
        tileViews(in: view).filter { !$0.isHidden }
    }

    func makeTiles(
        count: Int,
        valuePrefix: String = "Value"
    ) -> [WeatherTileViewData] {
        let identifiers: [WeatherTileIdentifier] = [
            .minimumTemperature,
            .maximumTemperature,
            .pressure,
            .wind,
            .visibility,
            .cloudCoverage,
            .sunrise,
            .sunset
        ]

        return identifiers.prefix(count).enumerated().map { index, identifier in
            makeTile(
                id: identifier,
                title: "Tile \(index)",
                valueText: "\(valuePrefix) \(index)"
            )
        }
    }

    func makeTile(
        id: WeatherTileIdentifier = .wind,
        title: String,
        valueText: String
    ) -> WeatherTileViewData {
        WeatherTileViewData(
            id: id,
            title: title,
            valueText: valueText,
            detailText: nil,
            symbolName: "circle"
        )
    }
}
