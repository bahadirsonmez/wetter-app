import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherViewTests: XCTestCase {

    func testViewHierarchyContainsSectionsInExpectedOrder() {
        let view = LocationWeatherView()

        guard let contentView = view.summaryContainerView.superview else {
            return XCTFail("Expected scroll view content view.")
        }

        XCTAssertTrue(contentView.superview === view.scrollView)
        XCTAssertEqual(
            contentView.subviews,
            [
                view.summaryContainerView,
                view.forecastContainerView,
                view.tilesContainerView
            ]
        )
    }

    func testRefreshControlIsAttachedToScrollView() {
        let view = LocationWeatherView()

        XCTAssertTrue(view.scrollView.refreshControl === view.refreshControl)
    }

    func testScrollViewAlwaysBouncesVertically() {
        let view = LocationWeatherView()

        XCTAssertTrue(view.scrollView.alwaysBounceVertical)
    }

    func testScrollViewUsesSafeAreaForVerticalViewport() {
        let view = LocationWeatherView()
        let verticalConstraints = view.constraints.filter {
            $0.firstItem === view.scrollView
                && ($0.firstAttribute == .top || $0.firstAttribute == .bottom)
        }

        XCTAssertEqual(verticalConstraints.count, 2)
        XCTAssertTrue(
            verticalConstraints.allSatisfy {
                $0.secondItem === view.safeAreaLayoutGuide
            }
        )
    }

    func testPositiveVerticalOffsetIsClampedToZero() {
        let view = LocationWeatherView()
        view.scrollView.contentOffset.y = 100

        view.scrollViewDidScroll(view.scrollView)

        XCTAssertEqual(view.scrollView.contentOffset.y, .zero)
    }

    func testNegativeVerticalOffsetIsPreservedForPullToRefresh() {
        let view = LocationWeatherView()
        view.scrollView.contentOffset.y = -100

        view.scrollViewDidScroll(view.scrollView)

        XCTAssertEqual(view.scrollView.contentOffset.y, -100)
    }

    func testContentViewWidthMatchesScrollViewFrameLayoutGuide() {
        let view = LocationWeatherView()

        guard let contentView = view.summaryContainerView.superview else {
            return XCTFail("Expected scroll view content view.")
        }

        let widthConstraint = view.scrollView.constraints.first {
            $0.firstItem === contentView
                && $0.firstAttribute == .width
                && $0.secondItem === view.scrollView.frameLayoutGuide
                && $0.secondAttribute == .width
                && $0.relation == .equal
        }

        XCTAssertNotNil(widthConstraint)
    }

    func testContentViewHeightMatchesScrollViewFrameLayoutGuide() {
        let view = LocationWeatherView()

        guard let contentView = view.summaryContainerView.superview else {
            return XCTFail("Expected scroll view content view.")
        }

        let heightConstraint = view.scrollView.constraints.first {
            $0.firstItem === contentView
                && $0.firstAttribute == .height
                && $0.secondItem === view.scrollView.frameLayoutGuide
                && $0.secondAttribute == .height
                && $0.relation == .equal
        }

        XCTAssertNotNil(heightConstraint)
    }

    func testContentDoesNotCreateVerticalScrollableRange() {
        let view = LocationWeatherView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844)
        )

        view.layoutIfNeeded()

        XCTAssertEqual(
            view.scrollView.contentSize.height,
            view.scrollView.bounds.height,
            accuracy: 0.001
        )
    }

    func testPlaceholderSectionsUseLowPriorityZeroHeightConstraints() {
        let view = LocationWeatherView()
        let sections = [
            view.summaryContainerView,
            view.forecastContainerView
        ]

        sections.forEach { section in
            let constraint = section.constraints.first {
                $0.firstAttribute == .height
                    && $0.secondItem == nil
                    && $0.constant == 0
                    && $0.relation == .equal
            }

            XCTAssertEqual(constraint?.priority, .defaultLow)
        }
    }

    func testTilesContainerUsesAutoLayoutWithinScreenHierarchy() {
        let view = LocationWeatherView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844)
        )

        view.layoutIfNeeded()

        XCTAssertFalse(
            view.tilesContainerView.translatesAutoresizingMaskIntoConstraints
        )

        XCTAssertEqual(
            view.tilesContainerView.frame.minY,
            view.forecastContainerView.frame.maxY
        )
        XCTAssertEqual(
            view.tilesContainerView.frame.maxY,
            view.summaryContainerView.superview?.bounds.maxY
        )
    }

    func testFeedbackViewsAreInitiallyHidden() {
        let view = LocationWeatherView()

        XCTAssertTrue(view.loadingView.isHidden)
        XCTAssertTrue(view.summaryContainerView.statusView.isHidden)
        XCTAssertTrue(view.forecastContainerView.temperatureGraphView.isHidden)
        XCTAssertTrue(view.forecastContainerView.statusView.isHidden)
    }

    func testForecastContainerContainsGraphAndLocalStatusViews() {
        let view = LocationWeatherView()

        XCTAssertTrue(
            view.forecastContainerView.temperatureGraphView.superview === view.forecastContainerView
        )
        XCTAssertTrue(
            view.forecastContainerView.statusView.superview === view.forecastContainerView
        )
    }

    func testTilesContainerContainsWeatherTilesView() {
        let view = LocationWeatherView()

        XCTAssertTrue(
            view.tilesContainerView.tilesView.superview
                === view.tilesContainerView
        )
    }

    func testBoundsSizeChangeInvalidatesDependentLayouts() {
        let view = LocationWeatherView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 844)
        )
        var tilesInvalidationCount = 0
        view.tilesContainerView.tilesView.onMinimumRequiredHeightChange = {
            tilesInvalidationCount += 1
        }
        view.layoutIfNeeded()

        view.frame.size = CGSize(width: 700, height: 600)
        view.setNeedsLayout()
        view.layoutIfNeeded()

        XCTAssertEqual(tilesInvalidationCount, 1)
    }
}
