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
                makeTile(
                    id: .wind,
                    title: "Wind",
                    valueText: "2 m/s"
                ),
                makeTile(
                    id: .cloudCoverage,
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

    func testInvalidateLayoutForBoundsChangeNotifiesHeightChange() {
        let view = makeView(size: CGSize(width: 390, height: 400))
        var notificationCount = 0
        view.onMinimumRequiredHeightChange = {
            notificationCount += 1
        }

        view.invalidateLayoutForBoundsChange()

        XCTAssertEqual(notificationCount, 1)
    }

    func testWidthIncreaseRecalculatesTileFrames() {
        let view = makeView(size: CGSize(width: 320, height: 500))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let compactFrames = visibleTileViews(in: view).map(\.frame)

        resize(view, to: CGSize(width: 700, height: 500))

        XCTAssertNotEqual(
            visibleTileViews(in: view).map(\.frame),
            compactFrames
        )
    }

    func testWidthDecreaseRecalculatesTileFrames() {
        let view = makeView(size: CGSize(width: 700, height: 500))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let expandedFrames = visibleTileViews(in: view).map(\.frame)

        resize(view, to: CGSize(width: 320, height: 500))

        XCTAssertNotEqual(
            visibleTileViews(in: view).map(\.frame),
            expandedFrames
        )
    }

    func testHeightDecreaseReducesVisibleTileCount() {
        let view = makeView(size: CGSize(width: 320, height: 700))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let expandedVisibleCount = visibleTileViews(in: view).count

        resize(view, to: CGSize(width: 320, height: 180))

        XCTAssertLessThan(
            visibleTileViews(in: view).count,
            expandedVisibleCount
        )
    }

    func testHeightIncreaseDoesNotReduceVisibleTileCount() {
        let view = makeView(size: CGSize(width: 320, height: 180))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let compactVisibleCount = visibleTileViews(in: view).count

        resize(view, to: CGSize(width: 320, height: 700))

        XCTAssertGreaterThanOrEqual(
            visibleTileViews(in: view).count,
            compactVisibleCount
        )
    }

    func testResizeReusesExistingTileViews() {
        let view = makeView(size: CGSize(width: 320, height: 300))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let existingTileViews = tileViews(in: view)

        resize(view, to: CGSize(width: 700, height: 500))

        XCTAssertEqual(tileViews(in: view).count, existingTileViews.count)
        XCTAssertTrue(
            zip(existingTileViews, tileViews(in: view)).allSatisfy {
                $0 === $1
            }
        )
    }

    func testResizeDoesNotChangePresentationOrder() {
        let view = makeView(size: CGSize(width: 320, height: 300))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()

        resize(view, to: CGSize(width: 700, height: 500))

        XCTAssertEqual(
            visibleTileViews(in: view).compactMap(\.titleLabel.text),
            (0..<visibleTileViews(in: view).count).map { "Tile \($0)" }
        )
    }

    func testResizePreservesUserDefinedOrder() {
        let view = configuredWideView()
        view.moveTile(with: .wind, toVisibleIndex: 0)

        resize(view, to: CGSize(width: 320, height: 300))

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.wind, .minimumTemperature, .maximumTemperature, .pressure]
        )
    }

    func testAccessibilitySizeRecalculatesMinimumHeight() {
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

    func testTilesHaveDragInteractions() {
        let view = makeView(size: CGSize(width: 900, height: 600))
        view.configure(with: makeTiles(count: 4))

        XCTAssertTrue(
            tileViews(in: view).allSatisfy {
                $0.interactions.contains { $0 is UIDragInteraction }
            }
        )
    }

    func testTilesViewHasSingleDropInteraction() {
        let view = makeView(size: CGSize(width: 900, height: 600))

        XCTAssertEqual(
            view.interactions.filter { $0 is UIDropInteraction }.count,
            1
        )
    }

    func testExternalDragSessionIsRejected() {
        let view = makeView(size: CGSize(width: 900, height: 600))

        XCTAssertFalse(view.acceptsDrop(isLocalSession: false))
        XCTAssertTrue(view.acceptsDrop(isLocalSession: true))
    }

    func testDropMovesTileToDestinationIndex() {
        let view = configuredWideView()

        view.moveTile(
            with: .minimumTemperature,
            toVisibleIndex: 2
        )

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.maximumTemperature, .pressure, .minimumTemperature, .wind]
        )
    }

    func testMovingForwardNormalizesDestinationIndex() {
        let view = configuredWideView()

        view.moveTile(with: .minimumTemperature, toVisibleIndex: 3)

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.maximumTemperature, .pressure, .wind, .minimumTemperature]
        )
    }

    func testMovingBackwardUpdatesOrder() {
        let view = configuredWideView()

        view.moveTile(with: .wind, toVisibleIndex: 1)

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.minimumTemperature, .wind, .maximumTemperature, .pressure]
        )
    }

    func testDroppingAtSameIndexDoesNotChangeOrder() {
        let view = configuredWideView()
        let originalOrder = configuredIdentifiers(in: view)

        view.moveTile(with: .pressure, toVisibleIndex: 2)

        XCTAssertEqual(configuredIdentifiers(in: view), originalOrder)
    }

    func testReorderPreservesTileIdentifiers() {
        let view = configuredWideView()
        let originalIdentifiers = Set(configuredIdentifiers(in: view))

        view.moveTile(with: .wind, toVisibleIndex: 0)

        XCTAssertEqual(
            Set(configuredIdentifiers(in: view)),
            originalIdentifiers
        )
    }

    func testRefreshPreservesUserDefinedOrder() {
        let view = configuredWideView()
        view.moveTile(with: .wind, toVisibleIndex: 0)

        view.configure(with: makeTiles(count: 4, valuePrefix: "Refreshed"))

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.wind, .minimumTemperature, .maximumTemperature, .pressure]
        )
        XCTAssertEqual(tileViews(in: view)[0].valueLabel.text, "Refreshed 3")
    }

    func testNewTileIsAppendedToPreferredOrder() {
        let view = configuredWideView()
        view.moveTile(with: .wind, toVisibleIndex: 0)

        view.configure(with: makeTiles(count: 5))

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [
                .wind,
                .minimumTemperature,
                .maximumTemperature,
                .pressure,
                .visibility
            ]
        )
    }

    func testRemovedTileIsRemovedFromPreferredOrder() {
        let view = configuredWideView()
        view.moveTile(with: .wind, toVisibleIndex: 0)
        let remainingTiles = makeTiles(count: 4).filter {
            $0.id != .maximumTemperature
        }

        view.configure(with: remainingTiles)

        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.wind, .minimumTemperature, .pressure]
        )
    }

    func testReorderReusesExistingTileViews() {
        let view = configuredWideView()
        let existingViews = tileViews(in: view)

        view.moveTile(with: .wind, toVisibleIndex: 0)

        XCTAssertEqual(tileViews(in: view).count, existingViews.count)
        XCTAssertTrue(
            zip(existingViews, tileViews(in: view)).allSatisfy { $0 === $1 }
        )
    }

    func testReorderDoesNotUseAutoLayout() {
        let view = configuredWideView()

        view.moveTile(with: .wind, toVisibleIndex: 0)

        XCTAssertTrue(view.constraints.isEmpty)
        XCTAssertTrue(tileViews(in: view).allSatisfy(\.constraints.isEmpty))
    }

    func testHiddenTilesPreserveRelativeOrder() {
        let view = makeView(size: CGSize(width: 500, height: 180))
        view.configure(with: makeTiles(count: 8))
        view.layoutIfNeeded()
        let visibleCount = visibleTileViews(in: view).count
        let hiddenOrder = Array(
            configuredIdentifiers(in: view).dropFirst(visibleCount)
        )

        guard visibleCount > 1 else {
            XCTFail("Test requires at least two visible tiles")
            return
        }

        view.moveTile(
            with: configuredIdentifiers(in: view)[1],
            toVisibleIndex: 0
        )

        XCTAssertEqual(
            Array(configuredIdentifiers(in: view).dropFirst(visibleCount)),
            hiddenOrder
        )
    }

    func testMiddleTileProvidesMoveEarlierAndLaterActions() {
        let view = configuredWideView()
        let actions = tileViews(in: view)[1].accessibilityCustomActions ?? []

        XCTAssertEqual(
            Set(actions.map(\.name)),
            ["Move Earlier", "Move Later"]
        )
    }

    func testFirstTileDoesNotProvideMoveEarlierAction() {
        let view = configuredWideView()
        let actionNames = tileViews(in: view)[0]
            .accessibilityCustomActions?
            .map(\.name) ?? []

        XCTAssertFalse(actionNames.contains("Move Earlier"))
        XCTAssertTrue(actionNames.contains("Move Later"))
    }

    func testLastTileDoesNotProvideMoveLaterAction() {
        let view = configuredWideView()
        let lastVisibleTile = try! XCTUnwrap(visibleTileViews(in: view).last)
        let actionNames = lastVisibleTile.accessibilityCustomActions?
            .map(\.name) ?? []

        XCTAssertTrue(actionNames.contains("Move Earlier"))
        XCTAssertFalse(actionNames.contains("Move Later"))
    }

    func testAccessibilityActionReordersTile() {
        let view = configuredWideView()
        let secondTile = tileViews(in: view)[1]

        XCTAssertTrue(
            secondTile.performMoveEarlierAccessibilityAction()
        )
        XCTAssertEqual(
            configuredIdentifiers(in: view),
            [.maximumTemperature, .minimumTemperature, .pressure, .wind]
        )
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

    func resize(_ view: WeatherTilesView, to size: CGSize) {
        view.frame.size = size
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func configuredWideView() -> WeatherTilesView {
        let view = makeView(size: CGSize(width: 900, height: 600))
        view.configure(with: makeTiles(count: 4))
        view.layoutIfNeeded()
        return view
    }

    func configuredIdentifiers(
        in view: WeatherTilesView
    ) -> [WeatherTileIdentifier] {
        tileViews(in: view).compactMap(\.identifier)
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
