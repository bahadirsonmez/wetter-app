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
        verticalSpacing: 20
    )

    func testLongerContentProducesWiderTile() {
        let result = makeLayout(
            availableSize: CGSize(width: 400, height: 180),
            items: [
                item(width: 80),
                item(width: 120)
            ]
        )

        XCTAssertGreaterThan(
            result.itemFrames[1].width,
            result.itemFrames[0].width
        )
    }

    func testRemainingRowWidthIsDistributedEqually() {
        let result = makeLayout(
            availableSize: CGSize(width: 400, height: 180),
            items: [
                item(width: 80),
                item(width: 120)
            ]
        )

        XCTAssertEqual(result.itemFrames[0].width, 145)
        XCTAssertEqual(result.itemFrames[1].width, 185)
    }

    func testRowsFillAvailableWidth() throws {
        let result = makeLayout(
            availableSize: CGSize(width: 400, height: 300),
            items: [
                item(width: 80),
                item(width: 120),
                item(width: 200)
            ]
        )
        let rows = Dictionary(grouping: result.itemFrames, by: \.minY)

        for frames in rows.values {
            let firstFrame = try XCTUnwrap(frames.min { $0.minX < $1.minX })
            let lastFrame = try XCTUnwrap(frames.max { $0.maxX < $1.maxX })

            XCTAssertEqual(firstFrame.minX, metrics.contentInsets.left)
            XCTAssertEqual(
                lastFrame.maxX,
                result.contentSize.width - metrics.contentInsets.right
            )
        }
    }

    func testRowsShareAvailableHeightEqually() {
        let result = makeLayout(
            availableSize: CGSize(width: 400, height: 300),
            items: [
                item(width: 200),
                item(width: 200)
            ]
        )

        XCTAssertEqual(result.itemFrames[0].height, 120)
        XCTAssertEqual(result.itemFrames[1].height, 120)
    }

    func testSmallViewportDisplaysLongestFittingPrefix() {
        let result = makeLayout(
            availableSize: CGSize(width: 400, height: 300),
            items: [
                item(width: 200, height: 80),
                item(width: 200, height: 80),
                item(width: 200, height: 80)
            ]
        )

        XCTAssertEqual(result.visibleItemCount, 2)
        XCTAssertEqual(result.itemFrames.count, 2)
    }

    func testLargerViewportDoesNotReduceVisibleItemCount() {
        let items = Array(
            repeating: item(width: 120, height: 80),
            count: 8
        )
        let compactResult = makeLayout(
            availableSize: CGSize(width: 320, height: 260),
            items: items
        )
        let expandedResult = makeLayout(
            availableSize: CGSize(width: 700, height: 500),
            items: items
        )

        XCTAssertGreaterThanOrEqual(
            expandedResult.visibleItemCount,
            compactResult.visibleItemCount
        )
    }

    func testLargerMinimumHeightReducesVisibleItemCount() {
        let regularResult = makeLayout(
            availableSize: CGSize(width: 400, height: 300),
            items: Array(
                repeating: item(width: 200, height: 80),
                count: 3
            )
        )
        let accessibilityResult = makeLayout(
            availableSize: CGSize(width: 400, height: 300),
            items: Array(
                repeating: item(width: 200, height: 130),
                count: 3
            )
        )

        XCTAssertLessThan(
            accessibilityResult.visibleItemCount,
            regularResult.visibleItemCount
        )
    }

    func testLastSingleTileFillsRowWidth() {
        let result = makeLayout(
            availableSize: CGSize(width: 400, height: 300),
            items: [
                item(width: 80),
                item(width: 120),
                item(width: 200)
            ]
        )
        let lastFrame = result.itemFrames[2]

        XCTAssertEqual(lastFrame.minX, metrics.contentInsets.left)
        XCTAssertEqual(
            lastFrame.maxX,
            result.contentSize.width - metrics.contentInsets.right
        )
    }

    func testItemFramesDoNotOverlap() {
        let frames = makeLayout(
            availableSize: CGSize(width: 700, height: 500),
            items: Array(
                repeating: item(width: 120),
                count: 8
            )
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
            availableSize: CGSize(width: 700, height: 500),
            items: Array(
                repeating: item(width: 120),
                count: 8
            )
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

    func testZeroItemsProducesNoFrames() {
        let result = makeLayout(
            availableSize: CGSize(width: 320, height: 400),
            items: []
        )

        XCTAssertTrue(result.itemFrames.isEmpty)
        XCTAssertEqual(result.visibleItemCount, 0)
        XCTAssertEqual(
            result.contentSize,
            CGSize(width: 320, height: 400)
        )
    }

    func testZeroAvailableHeightProducesNoFrames() {
        let result = makeLayout(
            availableSize: CGSize(width: 320, height: 0),
            items: [item(width: 100)]
        )

        XCTAssertTrue(result.itemFrames.isEmpty)
        XCTAssertEqual(result.visibleItemCount, 0)
    }
}

// MARK: - Helpers

private extension WeatherTilesLayoutTests {

    func makeLayout(
        availableSize: CGSize,
        items: [WeatherTilesLayoutItem]
    ) -> WeatherTilesLayoutResult {
        WeatherTilesLayout(metrics: metrics).makeLayout(
            availableSize: availableSize,
            items: items
        )
    }

    func item(
        width: CGFloat,
        height: CGFloat = 80
    ) -> WeatherTilesLayoutItem {
        WeatherTilesLayoutItem(
            preferredWidth: width,
            minimumHeight: height
        )
    }
}
