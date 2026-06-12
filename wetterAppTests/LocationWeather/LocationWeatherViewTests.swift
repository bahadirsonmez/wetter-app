import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherViewTests: XCTestCase {

    func testViewHierarchyContainsSectionsInExpectedOrder() {
        let view = LocationWeatherView()

        guard let contentView = view.summaryView.superview else {
            return XCTFail("Expected scroll view content view.")
        }

        XCTAssertTrue(contentView.superview === view.scrollView)
        XCTAssertEqual(
            contentView.subviews,
            [
                view.summaryView,
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

    func testContentViewWidthMatchesScrollViewFrameLayoutGuide() {
        let view = LocationWeatherView()

        guard let contentView = view.summaryView.superview else {
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

    func testPlaceholderSectionsUseLowPriorityZeroHeightConstraints() {
        let view = LocationWeatherView()
        let sections = [
            view.summaryView,
            view.forecastContainerView,
            view.tilesContainerView
        ]

        sections.forEach { section in
            let constraint = section.constraints.first {
                $0.firstAttribute == .height
                    && $0.secondItem == nil
                    && $0.constant == 0
            }

            XCTAssertEqual(constraint?.priority, .defaultLow)
        }
    }

    func testFeedbackViewsAreInitiallyHidden() {
        let view = LocationWeatherView()

        XCTAssertTrue(view.loadingView.isHidden)
        XCTAssertTrue(view.statusView.isHidden)
    }
}
