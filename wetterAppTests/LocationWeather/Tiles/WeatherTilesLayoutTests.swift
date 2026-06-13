import XCTest
@testable import wetterApp

final class WeatherTilesLayoutTests: XCTestCase {

    private let metrics = WeatherTilesLayoutMetrics(
        contentInsets: UIEdgeInsets(
            top: 10,
            left: 20,
            bottom: 30,
            right: 40
        ),
        horizontalSpacing: 10,
        verticalSpacing: 20,
        compactMaximumItemCount: 4,
        mediumMaximumItemCount: 6,
        wideMaximumItemCount: 8
    )

    func testCompactWidthUsesTwoColumns() {
        let result = makeLayout(
            availableWidth: 490,
            itemCount: 8
        )

        XCTAssertEqual(
            Set(result.itemFrames.map(\.minX)).count,
            2
        )
    }

    func testMediumWidthUsesThreeColumns() {
        let result = makeLayout(
            availableWidth: 500,
            itemCount: 8
        )

        XCTAssertEqual(
            Set(result.itemFrames.map(\.minX)).count,
            3
        )
    }

    func testWideWidthUsesFourColumns() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 8
        )

        XCTAssertEqual(
            Set(result.itemFrames.map(\.minX)).count,
            4
        )
    }

    func testCompactWidthDisplaysFourItems() {
        let result = makeLayout(
            availableWidth: 490,
            itemCount: 8
        )

        XCTAssertEqual(result.visibleItemCount, 4)
        XCTAssertEqual(result.itemFrames.count, 4)
    }

    func testMediumWidthDisplaysSixItems() {
        let result = makeLayout(
            availableWidth: 500,
            itemCount: 8
        )

        XCTAssertEqual(result.visibleItemCount, 6)
        XCTAssertEqual(result.itemFrames.count, 6)
    }

    func testWideWidthDisplaysEightItems() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 8
        )

        XCTAssertEqual(result.visibleItemCount, 8)
        XCTAssertEqual(result.itemFrames.count, 8)
    }

    func testItemFramesDoNotOverlap() {
        let frames = makeLayout(
            availableWidth: 900,
            itemCount: 8
        ).itemFrames

        for firstIndex in frames.indices {
            for secondIndex in frames.indices where secondIndex > firstIndex {
                XCTAssertFalse(
                    frames[firstIndex].intersects(frames[secondIndex])
                )
            }
        }
    }

    func testItemFramesRespectContentInsets() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 8
        )

        result.itemFrames.forEach { frame in
            XCTAssertGreaterThanOrEqual(frame.minX, metrics.contentInsets.left)
            XCTAssertGreaterThanOrEqual(frame.minY, metrics.contentInsets.top)
            XCTAssertLessThanOrEqual(
                frame.maxX,
                result.contentSize.width - metrics.contentInsets.right
            )
            XCTAssertLessThanOrEqual(
                frame.maxY,
                result.contentSize.height - metrics.contentInsets.bottom
            )
        }
    }

    func testTilesAreSquare() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 8
        )

        result.itemFrames.forEach {
            XCTAssertEqual($0.width, $0.height)
        }
    }

    func testContentHeightIncludesLastRow() throws {
        let result = makeLayout(
            availableWidth: 500,
            itemCount: 4
        )
        let lastRowMaximumY = try XCTUnwrap(
            result.itemFrames.map(\.maxY).max()
        )

        XCTAssertEqual(
            result.contentSize.height,
            lastRowMaximumY + metrics.contentInsets.bottom
        )
    }

    func testAccessibilityCategoryReducesColumnCount() {
        let result = makeLayout(
            availableWidth: 490,
            itemCount: 4,
            contentSizeCategory: .accessibilityLarge
        )

        XCTAssertEqual(
            Set(result.itemFrames.map(\.minX)).count,
            1
        )
    }

    func testItemCountBelowWidthLimitOnlyCreatesAvailableItems() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 3
        )

        XCTAssertEqual(result.visibleItemCount, 3)
        XCTAssertEqual(result.itemFrames.count, 3)
    }

    func testZeroItemsProducesZeroHeight() {
        let result = makeLayout(
            availableWidth: 320,
            itemCount: 0
        )

        XCTAssertTrue(result.itemFrames.isEmpty)
        XCTAssertEqual(result.visibleItemCount, 0)
        XCTAssertEqual(
            result.contentSize,
            CGSize(width: 320, height: 0)
        )
    }

    func testWidthChangeProducesNewFrames() {
        let compactResult = makeLayout(
            availableWidth: 490,
            itemCount: 8
        )
        let wideResult = makeLayout(
            availableWidth: 900,
            itemCount: 8
        )

        XCTAssertNotEqual(compactResult.itemFrames, wideResult.itemFrames)
    }

    func testInsufficientWidthProducesZeroSizedFrames() {
        let result = makeLayout(
            availableWidth: 40,
            itemCount: 2
        )

        XCTAssertEqual(
            result.itemFrames.map(\.size),
            [.zero, .zero]
        )
        XCTAssertEqual(
            result.contentSize,
            CGSize(width: 40, height: 40)
        )
    }
}

// MARK: - Helpers

private extension WeatherTilesLayoutTests {

    func makeLayout(
        availableWidth: CGFloat,
        itemCount: Int,
        contentSizeCategory: UIContentSizeCategory = .large
    ) -> WeatherTilesLayoutResult {
        WeatherTilesLayout(metrics: metrics).makeLayout(
            availableWidth: availableWidth,
            itemCount: itemCount,
            contentSizeCategory: contentSizeCategory
        )
    }
}
