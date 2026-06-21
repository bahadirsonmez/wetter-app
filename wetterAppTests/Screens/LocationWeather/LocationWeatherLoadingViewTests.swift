import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherLoadingViewTests: XCTestCase {

    func testActivityIndicatorStartsAnimating() {
        let view = LocationWeatherLoadingView()

        XCTAssertTrue(view.activityIndicator.isAnimating)
    }

    func testActivityIndicatorHidesWhenStopped() {
        let view = LocationWeatherLoadingView()

        XCTAssertTrue(view.activityIndicator.hidesWhenStopped)
    }
}
