import UIKit
import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherScreenLifecycleTests: XCTestCase {

    func testViewControllerDeallocatesAfterRelease() {
        let viewModel = LocationWeatherViewModelSpy()
        let locationProvider = CurrentLocationProviderSpy()
        weak var weakViewController: LocationWeatherViewController?

        autoreleasepool {
            var viewController: LocationWeatherViewController? =
                LocationWeatherViewController(
                    viewModel: viewModel,
                    locationProvider: locationProvider
                )
            viewController?.loadViewIfNeeded()
            weakViewController = viewController
            viewController = nil
        }

        XCTAssertNil(weakViewController)
    }

    func testLocationProviderDoesNotRetainViewController() {
        let viewModel = LocationWeatherViewModelSpy()
        let locationProvider = CurrentLocationProviderSpy()
        weak var weakViewController: LocationWeatherViewController?

        autoreleasepool {
            var viewController: LocationWeatherViewController? =
                LocationWeatherViewController(
                    viewModel: viewModel,
                    locationProvider: locationProvider
                )
            viewController?.loadViewIfNeeded()
            weakViewController = viewController
            viewController = nil
        }

        XCTAssertNotNil(locationProvider.onLocationResult)
        XCTAssertNil(weakViewController)
    }

    func testViewModelCallbackDoesNotRetainViewController() {
        let viewModel = LocationWeatherViewModelSpy()
        let locationProvider = CurrentLocationProviderSpy()
        weak var weakViewController: LocationWeatherViewController?

        autoreleasepool {
            var viewController: LocationWeatherViewController? =
                LocationWeatherViewController(
                    viewModel: viewModel,
                    locationProvider: locationProvider
                )
            viewController?.loadViewIfNeeded()
            weakViewController = viewController
            viewController = nil
        }

        XCTAssertNotNil(viewModel.onStateChange)
        XCTAssertNil(weakViewController)
    }

    func testRepeatedResizeDoesNotCreateAdditionalTileViews() {
        let tilesView = WeatherTilesView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 400)
        )
        tilesView.configure(
            with: LocationWeatherViewDataFixture.tiles()
        )
        tilesView.layoutIfNeeded()
        let initialTileViews = tileViews(in: tilesView)
        let sizes = [
            CGSize(width: 320, height: 180),
            CGSize(width: 507, height: 400),
            CGSize(width: 834, height: 600),
            CGSize(width: 390, height: 300)
        ]

        for _ in 0..<5 {
            for size in sizes {
                resize(tilesView, to: size)
            }
        }

        let resizedTileViews = tileViews(in: tilesView)
        XCTAssertEqual(resizedTileViews.count, initialTileViews.count)
        XCTAssertTrue(
            zip(initialTileViews, resizedTileViews).allSatisfy(===)
        )
    }

    func testRepeatedResizeDoesNotReloadForecastData() {
        let layout = InvalidationTrackingLayout()
        let collectionView = ReloadTrackingCollectionView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 220),
            collectionViewLayout: layout
        )
        let graphView = TemperatureGraphView(
            frame: collectionView.frame,
            collectionView: collectionView
        )
        graphView.configure(
            with: LocationWeatherViewDataFixture.berlin().hourlyForecast
        )
        let reloadCount = collectionView.reloadDataCallCount
        let sizes = [
            CGSize(width: 320, height: 180),
            CGSize(width: 507, height: 220),
            CGSize(width: 834, height: 260),
            CGSize(width: 390, height: 200)
        ]

        for _ in 0..<5 {
            for size in sizes {
                graphView.frame.size = size
                graphView.collectionView.frame = graphView.bounds
                graphView.invalidateLayoutForBoundsChange()
                graphView.layoutIfNeeded()
            }
        }

        XCTAssertEqual(collectionView.reloadDataCallCount, reloadCount)
        XCTAssertGreaterThan(layout.invalidateLayoutCallCount, .zero)
    }
}

// MARK: - Helpers

private extension LocationWeatherScreenLifecycleTests {

    func tileViews(in view: WeatherTilesView) -> [WeatherTileView] {
        view.subviews.compactMap { $0 as? WeatherTileView }
    }

    func resize(_ view: WeatherTilesView, to size: CGSize) {
        view.frame.size = size
        view.setNeedsLayout()
        view.layoutIfNeeded()
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
