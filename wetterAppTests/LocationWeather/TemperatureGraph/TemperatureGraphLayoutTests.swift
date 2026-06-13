import UIKit
import XCTest
@testable import wetterApp

@MainActor
final class TemperatureGraphLayoutTests: XCTestCase {

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

    func testPrepareCreatesItemAndHeaderAttributes() throws {
        let context = makeSUT(sectionItemCounts: [2, 1])

        context.layout.prepare()

        let item = try XCTUnwrap(
            context.layout.layoutAttributesForItem(
                at: IndexPath(item: 1, section: 0)
            )
        )
        let header = try XCTUnwrap(
            context.layout.layoutAttributesForSupplementaryView(
                ofKind: ForecastDayHeaderView.elementKind,
                at: IndexPath(item: 0, section: 1)
            )
        )

        XCTAssertEqual(
            item.frame,
            CGRect(x: 75, y: 40, width: 50, height: 60)
        )
        XCTAssertEqual(
            header.frame,
            CGRect(x: 145, y: 10, width: 50, height: 20)
        )
        XCTAssertEqual(header.zIndex, 1_000)
    }

    func testCollectionViewContentSizeUsesGeometry() {
        let context = makeSUT(sectionItemCounts: [2, 1])

        context.layout.prepare()

        XCTAssertEqual(
            context.layout.collectionViewContentSize,
            CGSize(width: 235, height: 130)
        )
    }

    func testAttributesForElementsReturnsOnlyIntersectingAttributes() {
        let context = makeSUT(sectionItemCounts: [2, 1])
        context.layout.prepare()

        let attributes = context.layout.layoutAttributesForElements(
            in: CGRect(x: 75, y: 40, width: 50, height: 60)
        )

        XCTAssertEqual(attributes?.count, 1)
        XCTAssertEqual(
            attributes?.first?.indexPath,
            IndexPath(item: 1, section: 0)
        )
    }

    func testSupplementaryAttributesRejectUnsupportedKinds() {
        let context = makeSUT(sectionItemCounts: [1])
        context.layout.prepare()

        let attributes = context.layout
            .layoutAttributesForSupplementaryView(
                ofKind: "Unsupported",
                at: IndexPath(item: 0, section: 0)
            )

        XCTAssertNil(attributes)
    }

    func testHeaderSticksToVisibleLeftEdge() throws {
        let context = makeSUT(sectionItemCounts: [2, 1])
        context.layout.prepare()
        context.collectionView.contentOffset.x = 30

        let header = try XCTUnwrap(
            context.layout.layoutAttributesForSupplementaryView(
                ofKind: ForecastDayHeaderView.elementKind,
                at: IndexPath(item: 0, section: 0)
            )
        )

        XCTAssertEqual(header.frame.minX, 30)
    }

    func testNextHeaderPushesCurrentHeaderLeft() throws {
        let context = makeSUT(sectionItemCounts: [2, 1])
        context.layout.prepare()
        context.collectionView.contentOffset.x = 80

        let header = try XCTUnwrap(
            context.layout.layoutAttributesForSupplementaryView(
                ofKind: ForecastDayHeaderView.elementKind,
                at: IndexPath(item: 0, section: 0)
            )
        )

        XCTAssertEqual(header.frame.minX, 40)
        XCTAssertEqual(header.frame.maxX, 145)
    }

    func testLastHeaderFollowsVisibleLeftEdge() throws {
        let context = makeSUT(sectionItemCounts: [2, 2])
        context.layout.prepare()
        context.collectionView.contentOffset.x = 160

        let header = try XCTUnwrap(
            context.layout.layoutAttributesForSupplementaryView(
                ofKind: ForecastDayHeaderView.elementKind,
                at: IndexPath(item: 0, section: 1)
            )
        )

        XCTAssertEqual(header.frame.minX, 160)
    }

    func testBoundsOriginChangeInvalidatesLayout() {
        let context = makeSUT(sectionItemCounts: [1])
        let newBounds = context.collectionView.bounds.offsetBy(
            dx: 1,
            dy: 0
        )

        XCTAssertTrue(
            context.layout.shouldInvalidateLayout(
                forBoundsChange: newBounds
            )
        )
    }

    func testUnchangedBoundsDoNotInvalidateLayout() {
        let context = makeSUT(sectionItemCounts: [1])

        XCTAssertFalse(
            context.layout.shouldInvalidateLayout(
                forBoundsChange: context.collectionView.bounds
            )
        )
    }

    private func makeSUT(
        sectionItemCounts: [Int]
    ) -> (
        layout: TemperatureGraphLayout,
        collectionView: UICollectionView,
        dataSource: CollectionViewDataSource
    ) {
        let layout = TemperatureGraphLayout(metrics: metrics)
        let collectionView = UICollectionView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 200),
            collectionViewLayout: layout
        )
        let dataSource = CollectionViewDataSource(
            sectionItemCounts: sectionItemCounts
        )
        collectionView.dataSource = dataSource
        collectionView.reloadData()

        return (layout, collectionView, dataSource)
    }
}

private final class CollectionViewDataSource:
    NSObject,
    UICollectionViewDataSource {

    private let sectionItemCounts: [Int]

    init(sectionItemCounts: [Int]) {
        self.sectionItemCounts = sectionItemCounts
    }

    func numberOfSections(
        in collectionView: UICollectionView
    ) -> Int {
        sectionItemCounts.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        numberOfItemsInSection section: Int
    ) -> Int {
        sectionItemCounts[section]
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        UICollectionViewCell()
    }
}
