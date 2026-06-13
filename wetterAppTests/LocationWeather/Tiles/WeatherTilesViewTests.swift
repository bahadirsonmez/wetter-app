import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class WeatherTilesViewTests: XCTestCase {

    func testConfigureCreatesRequiredTileViews() {
        let view = makeView(width: 900)

        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()

        XCTAssertEqual(tileViews(in: view).count, 8)
        XCTAssertEqual(
            tileViews(in: view).filter { !$0.isHidden }.count,
            8
        )
    }

    func testConfigureReusesExistingTileViews() {
        let view = makeView(width: 900)
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
        let view = makeView(width: 900)
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

    func testCompactWidthShowsOnlyFirstFourTiles() {
        let view = makeView(width: 390)

        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()

        XCTAssertEqual(
            tileViews(in: view).filter { !$0.isHidden }.count,
            4
        )
    }

    func testWidthChangeRecalculatesVisibleTileCountAndFrames() {
        let view = makeView(width: 390)
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let compactFrame = tileViews(in: view)[0].frame

        view.frame.size.width = 900
        view.setNeedsLayout()
        view.layoutIfNeeded()

        XCTAssertEqual(
            tileViews(in: view).filter { !$0.isHidden }.count,
            8
        )
        XCTAssertNotEqual(tileViews(in: view)[0].frame, compactFrame)
    }

    func testLayoutUpdatesIntrinsicContentHeight() {
        let view = makeView(width: 390)
        view.configure(with: makeTiles(count: 4))

        view.layoutIfNeeded()

        XCTAssertEqual(
            view.intrinsicContentSize.height,
            390
        )
    }

    func testResetHidesAndReusesTileViews() {
        let view = makeView(width: 900)
        view.configure(with: makeTiles(count: 4))
        let existingViews = tileViews(in: view)

        view.reset()
        view.configure(with: makeTiles(count: 2, valuePrefix: "New"))
        view.layoutIfNeeded()

        XCTAssertEqual(tileViews(in: view).count, 4)
        XCTAssertTrue(tileViews(in: view)[0] === existingViews[0])
        XCTAssertTrue(tileViews(in: view)[1] === existingViews[1])
        XCTAssertEqual(
            tileViews(in: view).filter { !$0.isHidden }.count,
            2
        )
        XCTAssertEqual(view.intrinsicContentSize.height, 240)
    }

    func testViewUsesOnlyManualSubviewLayout() {
        let view = makeView(width: 390)
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

    func makeView(width: CGFloat) -> WeatherTilesView {
        WeatherTilesView(
            frame: CGRect(x: 0, y: 0, width: width, height: 1_000)
        )
    }

    func tileViews(in view: WeatherTilesView) -> [WeatherTileView] {
        view.subviews.compactMap { $0 as? WeatherTileView }
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
            WeatherTileViewData(
                id: identifier,
                title: "Tile \(index)",
                valueText: "\(valuePrefix) \(index)",
                detailText: nil,
                symbolName: "circle"
            )
        }
    }
}
