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

    func testCompactWidthUsesTwoColumnsAndShowsFirstFourItems() {
        let result = makeLayout(
            availableWidth: 490,
            itemCount: 8
        )

        XCTAssertEqual(result.visibleItemCount, 4)
        XCTAssertEqual(
            result.itemFrames,
            [
                CGRect(x: 20, y: 10, width: 210, height: 210),
                CGRect(x: 240, y: 10, width: 210, height: 210),
                CGRect(x: 20, y: 240, width: 210, height: 210),
                CGRect(x: 240, y: 240, width: 210, height: 210)
            ]
        )
        XCTAssertEqual(
            result.contentSize,
            CGSize(width: 490, height: 480)
        )
    }

    func testMediumWidthUsesThreeColumnsAndShowsFirstSixItems() {
        let result = makeLayout(
            availableWidth: 500,
            itemCount: 8
        )

        XCTAssertEqual(result.visibleItemCount, 6)
        XCTAssertEqual(result.itemFrames.count, 6)
        XCTAssertEqual(result.itemFrames[0].minX, 20)
        XCTAssertEqual(result.itemFrames[1].minX, 170)
        XCTAssertEqual(result.itemFrames[2].minX, 320)
        XCTAssertEqual(result.itemFrames[3].minY, 170)
        XCTAssertEqual(result.itemFrames[0].size, CGSize(width: 140, height: 140))
        XCTAssertEqual(
            result.contentSize,
            CGSize(width: 500, height: 340)
        )
    }

    func testWideWidthUsesFourColumnsAndShowsAllEightItems() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 8
        )

        XCTAssertEqual(result.visibleItemCount, 8)
        XCTAssertEqual(result.itemFrames.count, 8)
        XCTAssertEqual(
            result.itemFrames[0].size,
            CGSize(width: 202.5, height: 202.5)
        )
        XCTAssertEqual(result.itemFrames[4].minY, 232.5)
        XCTAssertEqual(
            result.contentSize,
            CGSize(width: 900, height: 465)
        )
    }

    func testAccessibilityCategoryReducesColumnCountByOne() {
        let compactResult = makeLayout(
            availableWidth: 490,
            itemCount: 4,
            contentSizeCategory: .accessibilityLarge
        )
        let mediumResult = makeLayout(
            availableWidth: 500,
            itemCount: 6,
            contentSizeCategory: .accessibilityLarge
        )
        let wideResult = makeLayout(
            availableWidth: 900,
            itemCount: 8,
            contentSizeCategory: .accessibilityLarge
        )

        XCTAssertEqual(compactResult.itemFrames[1].minX, 20)
        XCTAssertEqual(mediumResult.itemFrames[2].minX, 20)
        XCTAssertEqual(wideResult.itemFrames[3].minX, 20)
    }

    func testItemCountBelowWidthLimitOnlyCreatesAvailableItems() {
        let result = makeLayout(
            availableWidth: 900,
            itemCount: 3
        )

        XCTAssertEqual(result.visibleItemCount, 3)
        XCTAssertEqual(result.itemFrames.count, 3)
    }

    func testEmptyItemsProduceEmptyLayout() {
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
