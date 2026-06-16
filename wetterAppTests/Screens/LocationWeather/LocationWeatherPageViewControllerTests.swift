import UIKit
import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherPageViewControllerTests: XCTestCase {

    func testUpdateSelectsRequestedSourceAndPageControlIndex() {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()
        sut.loadViewIfNeeded()

        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .saved(berlin)
        )

        XCTAssertEqual(sut.currentWeatherViewController?.source, .saved(berlin))
        XCTAssertEqual(sut.pageControl.currentPage, 1)
        XCTAssertEqual(sut.pageControl.numberOfPages, 2)
    }

    func testUpdateBeforeViewLoadsPreservesSelectedPageControlIndex() {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()

        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .saved(berlin)
        )
        sut.loadViewIfNeeded()

        XCTAssertEqual(sut.currentWeatherViewController?.source, .saved(berlin))
        XCTAssertEqual(sut.pageControl.currentPage, 1)
    }

    func testDataSourceReturnsPreviousAndNextSources() throws {
        let berlin = makeLocation(name: "Berlin")
        let hamburg = makeLocation(name: "Hamburg")
        let sut = makeSUT()
        sut.update(
            sources: [.current, .saved(berlin), .saved(hamburg)],
            selectedSource: .saved(berlin)
        )
        let current = try XCTUnwrap(sut.currentWeatherViewController)

        let previous = sut.pageViewController(
            sut.pageViewController,
            viewControllerBefore: current
        ) as? LocationWeatherViewController
        let next = sut.pageViewController(
            sut.pageViewController,
            viewControllerAfter: current
        ) as? LocationWeatherViewController

        XCTAssertEqual(previous?.source, .current)
        XCTAssertEqual(next?.source, .saved(hamburg))
    }

    func testAddingSourceKeepsCurrentControllerAndMakesNextPageAvailable()
        throws {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()
        sut.loadViewIfNeeded()
        sut.update(
            sources: [.current],
            selectedSource: .current
        )
        let current = try XCTUnwrap(sut.currentWeatherViewController)

        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .current
        )

        let next = sut.pageViewController(
            sut.pageViewController,
            viewControllerAfter: current
        ) as? LocationWeatherViewController
        XCTAssertTrue(sut.currentWeatherViewController === current)
        XCTAssertEqual(next?.source, .saved(berlin))
        XCTAssertTrue(sut.pageViewController.dataSource === sut)
    }

    func testDataSourceReturnsNilAtBoundaries() throws {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()
        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .current
        )
        let first = try XCTUnwrap(sut.currentWeatherViewController)

        XCTAssertNil(
            sut.pageViewController(
                sut.pageViewController,
                viewControllerBefore: first
            )
        )

        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .saved(berlin)
        )
        let last = try XCTUnwrap(sut.currentWeatherViewController)

        XCTAssertNil(
            sut.pageViewController(
                sut.pageViewController,
                viewControllerAfter: last
            )
        )
    }

    func testPageControlSelectionChangesSourceAndPublishesCallback() {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()
        var receivedSources: [LocationWeatherSource] = []
        sut.onSourceChange = { receivedSources.append($0) }
        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .current
        )

        sut.pageControl.currentPage = 1
        sut.pageControlChanged()

        XCTAssertEqual(sut.currentWeatherViewController?.source, .saved(berlin))
        XCTAssertEqual(receivedSources, [.saved(berlin)])

        sut.pageControl.currentPage = 0
        sut.pageControlChanged()

        XCTAssertEqual(sut.currentWeatherViewController?.source, .current)
        XCTAssertEqual(receivedSources, [.saved(berlin), .current])
    }

    func testCompletedSwipeUpdatesPageControlAndPublishesSource() throws {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()
        var receivedSource: LocationWeatherSource?
        sut.onSourceChange = { receivedSource = $0 }
        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .current
        )
        let current = try XCTUnwrap(sut.currentWeatherViewController)
        let next = try XCTUnwrap(
            sut.pageViewController(
                sut.pageViewController,
                viewControllerAfter: current
            ) as? LocationWeatherViewController
        )
        sut.pageViewController.setViewControllers(
            [next],
            direction: .forward,
            animated: false
        )

        sut.pageViewController(
            sut.pageViewController,
            didFinishAnimating: true,
            previousViewControllers: [current],
            transitionCompleted: true
        )

        XCTAssertEqual(sut.pageControl.currentPage, 1)
        XCTAssertEqual(receivedSource, .saved(berlin))
    }

    func testCancelledSwipeDoesNotChangeSelectionOrPublishSource() throws {
        let berlin = makeLocation(name: "Berlin")
        let sut = makeSUT()
        var receivedSources: [LocationWeatherSource] = []
        sut.onSourceChange = { receivedSources.append($0) }
        sut.update(
            sources: [.current, .saved(berlin)],
            selectedSource: .current
        )
        let current = try XCTUnwrap(sut.currentWeatherViewController)

        sut.pageViewController(
            sut.pageViewController,
            didFinishAnimating: true,
            previousViewControllers: [current],
            transitionCompleted: false
        )

        XCTAssertEqual(sut.pageControl.currentPage, 0)
        XCTAssertTrue(receivedSources.isEmpty)
    }
}

// MARK: - Helpers

@MainActor
private extension LocationWeatherPageViewControllerTests {

    func makeSUT() -> LocationWeatherPageViewController {
        LocationWeatherPageViewController { source in
            LocationWeatherViewController(
                viewModel: LocationWeatherViewModelSpy(source: source)
            )
        }
    }

    func makeLocation(name: String) -> LocationWeatherRoute {
        LocationWeatherRoute(
            id: UUID(),
            name: name,
            country: "DE",
            latitude: 52.52,
            longitude: 13.405
        )
    }
}
