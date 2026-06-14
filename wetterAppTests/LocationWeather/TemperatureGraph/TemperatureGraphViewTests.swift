import UIKit
import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class TemperatureGraphViewTests: XCTestCase {

    func testCollectionViewKeepsHorizontalScrollingEnabled() {
        let context = makeSUT()

        XCTAssertTrue(context.collectionView.alwaysBounceHorizontal)
        XCTAssertFalse(context.collectionView.showsHorizontalScrollIndicator)
    }

    func testConfigureReloadsCollectionViewForChangedViewData() {
        let context = makeSUT()

        context.sut.configure(with: makeViewData())

        XCTAssertEqual(context.collectionView.reloadDataCallCount, 1)
    }

    func testConfigureDoesNotReloadCollectionViewForSameViewData() {
        let context = makeSUT()
        let viewData = makeViewData()
        context.sut.configure(with: viewData)

        context.sut.configure(with: viewData)

        XCTAssertEqual(context.collectionView.reloadDataCallCount, 1)
    }

    func testResetReloadsCollectionViewWhenDataExists() {
        let context = makeSUT()
        context.sut.configure(with: makeViewData())

        context.sut.reset()

        XCTAssertEqual(context.collectionView.reloadDataCallCount, 2)
        XCTAssertEqual(numberOfSections(in: context.sut), 0)
    }

    func testResetWithoutDataDoesNotReloadCollectionView() {
        let context = makeSUT()

        context.sut.reset()

        XCTAssertEqual(context.collectionView.reloadDataCallCount, 0)
    }

    func testDataSourceUsesDaysAsSectionsAndItemsAsRows() {
        let context = makeSUT()
        context.sut.configure(with: makeViewData())

        XCTAssertEqual(numberOfSections(in: context.sut), 2)
        XCTAssertEqual(
            numberOfItems(in: 0, collectionView: context.collectionView),
            2
        )
        XCTAssertEqual(
            numberOfItems(in: 1, collectionView: context.collectionView),
            1
        )
    }

    func testCellUsesNeighborsAcrossDaySections() throws {
        let context = makeSUT()
        context.sut.configure(with: makeViewData())

        let firstCell = try cell(
            at: IndexPath(item: 0, section: 0),
            in: context.collectionView
        )
        let secondCell = try cell(
            at: IndexPath(item: 1, section: 0),
            in: context.collectionView
        )
        let lastCell = try cell(
            at: IndexPath(item: 0, section: 1),
            in: context.collectionView
        )

        XCTAssertNil(
            firstCell.temperatureGraphLineView.configuration?
                .previousTemperature
        )
        XCTAssertEqual(
            firstCell.temperatureGraphLineView.configuration?.nextTemperature,
            20
        )
        XCTAssertEqual(
            secondCell.temperatureGraphLineView.configuration?
                .previousTemperature,
            10
        )
        XCTAssertEqual(
            secondCell.temperatureGraphLineView.configuration?.nextTemperature,
            30
        )
        XCTAssertEqual(
            lastCell.temperatureGraphLineView.configuration?
                .previousTemperature,
            20
        )
        XCTAssertNil(
            lastCell.temperatureGraphLineView.configuration?.nextTemperature
        )
    }

    func testSupplementaryViewDisplaysDayTitle() throws {
        let context = makeSUT()
        context.sut.configure(with: makeViewData())
        context.sut.layoutIfNeeded()
        context.collectionView.layoutIfNeeded()
        let dataSource = try XCTUnwrap(context.collectionView.dataSource)

        let header = try XCTUnwrap(
            dataSource.collectionView?(
                context.collectionView,
                viewForSupplementaryElementOfKind:
                    ForecastDayHeaderView.elementKind,
                at: IndexPath(item: 0, section: 1)
            ) as? ForecastDayHeaderView
        )

        XCTAssertEqual(header.titleLabel.text, "Sunday, Jun 14")
    }

    func testMissingItemReturnsEmptyCellInsteadOfCrashing() {
        let context = makeSUT()
        let dataSource = context.collectionView.dataSource

        let cell = dataSource?.collectionView(
            context.collectionView,
            cellForItemAt: IndexPath(item: 0, section: 0)
        )

        XCTAssertNotNil(cell)
        XCTAssertFalse(cell is HourlyForecastCell)
    }

    func testUnsupportedHeaderKindReturnsEmptyViewInsteadOfCrashing() {
        let context = makeSUT()
        let dataSource = context.collectionView.dataSource

        let header = dataSource?.collectionView?(
            context.collectionView,
            viewForSupplementaryElementOfKind: "UnsupportedHeader",
            at: IndexPath(item: 0, section: 0)
        )

        XCTAssertNotNil(header)
        XCTAssertFalse(header is ForecastDayHeaderView)
    }

    func testInvalidateLayoutForBoundsChangeInvalidatesCollectionLayout() {
        let layout = InvalidationTrackingLayout()
        let collectionView = ReloadTrackingCollectionView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 200),
            collectionViewLayout: layout
        )
        let sut = TemperatureGraphView(
            frame: collectionView.frame,
            collectionView: collectionView
        )

        sut.invalidateLayoutForBoundsChange()

        XCTAssertEqual(layout.invalidateLayoutCallCount, 1)
    }
}

// MARK: - Helpers

private extension TemperatureGraphViewTests {

    typealias SUTContext = (
        sut: TemperatureGraphView,
        collectionView: ReloadTrackingCollectionView
    )

    func makeSUT() -> SUTContext {
        let collectionView = ReloadTrackingCollectionView(
            frame: CGRect(x: 0, y: 0, width: 320, height: 200),
            collectionViewLayout: TemperatureGraphLayout()
        )
        let sut = TemperatureGraphView(
            frame: collectionView.frame,
            collectionView: collectionView
        )
        return (sut, collectionView)
    }

    func makeViewData() -> HourlyForecastViewData {
        HourlyForecastViewData(
            days: [
                .init(
                    id: 1,
                    title: "Saturday, Jun 13",
                    items: [
                        makeItem(id: 1, temperature: 10),
                        makeItem(id: 2, temperature: 20)
                    ]
                ),
                .init(
                    id: 2,
                    title: "Sunday, Jun 14",
                    items: [
                        makeItem(id: 3, temperature: 30)
                    ]
                )
            ],
            minimumTemperature: 10,
            maximumTemperature: 30
        )
    }

    func makeItem(
        id: Int,
        temperature: Double
    ) -> HourlyForecastItemViewData {
        HourlyForecastItemViewData(
            id: id,
            timeText: "15:00",
            temperatureText: "\(Int(temperature))°C",
            conditionText: "Clear sky",
            temperatureValue: temperature
        )
    }

    func numberOfSections(
        in sut: TemperatureGraphView
    ) -> Int {
        sut.collectionView.dataSource?.numberOfSections?(
            in: sut.collectionView
        ) ?? 0
    }

    func numberOfItems(
        in section: Int,
        collectionView: UICollectionView
    ) -> Int {
        collectionView.dataSource?.collectionView(
            collectionView,
            numberOfItemsInSection: section
        ) ?? 0
    }

    func cell(
        at indexPath: IndexPath,
        in collectionView: UICollectionView
    ) throws -> HourlyForecastCell {
        let dataSource = try XCTUnwrap(collectionView.dataSource)
        return try XCTUnwrap(
            dataSource.collectionView(
                collectionView,
                cellForItemAt: indexPath
            ) as? HourlyForecastCell
        )
    }
}

private final class ReloadTrackingCollectionView: UICollectionView {

    private(set) var reloadDataCallCount = 0

    override func reloadData() {
        reloadDataCallCount += 1
        super.reloadData()
    }
}

private final class InvalidationTrackingLayout: UICollectionViewLayout {

    private(set) var invalidateLayoutCallCount = 0

    override func invalidateLayout() {
        invalidateLayoutCallCount += 1
        super.invalidateLayout()
    }
}
