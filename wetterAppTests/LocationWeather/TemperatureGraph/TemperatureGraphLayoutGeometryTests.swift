import XCTest
@testable import wetterApp

final class TemperatureGraphLayoutGeometryTests: XCTestCase {

    private let metrics = TemperatureGraphLayoutMetrics(
        itemSize: CGSize(width: 50, height: 60),
        itemSpacing: 5,
        sectionSpacing: 20,
        headerHeight: 20,
        headerSpacing: 10,
        contentInsets: UIEdgeInsets(
            top: 10,
            left: 20,
            bottom: 30,
            right: 40
        )
    )

    func testGeometryPositionsHeadersAndItemsAcrossSections() {
        let geometry = TemperatureGraphLayoutGeometry(
            sectionItemCounts: [2, 1],
            containerSize: CGSize(width: 100, height: 200),
            metrics: metrics
        )

        XCTAssertEqual(
            geometry.headerFrame(in: 0),
            CGRect(x: 20, y: 10, width: 105, height: 20)
        )
        XCTAssertEqual(
            geometry.itemFrame(at: IndexPath(item: 0, section: 0)),
            CGRect(x: 20, y: 40, width: 50, height: 60)
        )
        XCTAssertEqual(
            geometry.itemFrame(at: IndexPath(item: 1, section: 0)),
            CGRect(x: 75, y: 40, width: 50, height: 60)
        )
        XCTAssertEqual(
            geometry.headerFrame(in: 1),
            CGRect(x: 145, y: 10, width: 50, height: 20)
        )
        XCTAssertEqual(
            geometry.itemFrame(at: IndexPath(item: 0, section: 1)),
            CGRect(x: 145, y: 40, width: 50, height: 60)
        )
    }

    func testGeometryCalculatesScrollableContentSize() {
        let geometry = TemperatureGraphLayoutGeometry(
            sectionItemCounts: [2, 1],
            containerSize: CGSize(width: 100, height: 200),
            metrics: metrics
        )

        XCTAssertEqual(
            geometry.contentSize,
            CGSize(width: 235, height: 130)
        )
    }

    func testGeometryUsesContainerWidthWhenContentIsNarrower() {
        let geometry = TemperatureGraphLayoutGeometry(
            sectionItemCounts: [1],
            containerSize: CGSize(width: 320, height: 200),
            metrics: metrics
        )

        XCTAssertEqual(geometry.contentSize.width, 320)
    }

    func testGeometryWithNoSectionsProducesEmptyHeight() {
        let geometry = TemperatureGraphLayoutGeometry(
            sectionItemCounts: [],
            containerSize: CGSize(width: 320, height: 200),
            metrics: metrics
        )

        XCTAssertTrue(geometry.sections.isEmpty)
        XCTAssertEqual(
            geometry.contentSize,
            CGSize(width: 320, height: 0)
        )
    }

    func testGeometryReturnsNilForInvalidIndexPaths() {
        let geometry = TemperatureGraphLayoutGeometry(
            sectionItemCounts: [1],
            containerSize: .zero,
            metrics: metrics
        )

        XCTAssertNil(
            geometry.itemFrame(at: IndexPath(item: 1, section: 0))
        )
        XCTAssertNil(geometry.headerFrame(in: 1))
    }
}
