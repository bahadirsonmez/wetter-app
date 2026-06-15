import XCTest
@testable import wetterApp

final class WeatherTilesReorderGeometryTests: XCTestCase {

    private let frames = [
        CGRect(x: 10, y: 10, width: 80, height: 80),
        CGRect(x: 100, y: 10, width: 120, height: 80),
        CGRect(x: 10, y: 100, width: 210, height: 80)
    ]

    func testLocationInsideTileReturnsItsIndex() {
        XCTAssertEqual(
            WeatherTilesReorderGeometry.destinationIndex(
                for: CGPoint(x: 130, y: 40),
                visibleFrames: frames
            ),
            1
        )
    }

    func testLocationBetweenTilesReturnsNearestIndex() {
        XCTAssertEqual(
            WeatherTilesReorderGeometry.destinationIndex(
                for: CGPoint(x: 95, y: 40),
                visibleFrames: frames
            ),
            0
        )
    }

    func testLocationAfterLastTileReturnsLastIndex() {
        XCTAssertEqual(
            WeatherTilesReorderGeometry.destinationIndex(
                for: CGPoint(x: 250, y: 140),
                visibleFrames: frames
            ),
            2
        )
    }

    func testLocationOutsideVisibleAreaReturnsNil() {
        XCTAssertNil(
            WeatherTilesReorderGeometry.destinationIndex(
                for: CGPoint(x: 100, y: 250),
                visibleFrames: frames
            )
        )
    }

    func testEmptyFramesReturnNil() {
        XCTAssertNil(
            WeatherTilesReorderGeometry.destinationIndex(
                for: .zero,
                visibleFrames: []
            )
        )
    }
}
