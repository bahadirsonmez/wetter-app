import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherViewControllerTests: XCTestCase {

    func testViewUsesSystemBackgroundColor() {
        let viewController = LocationWeatherViewController()

        viewController.loadViewIfNeeded()

        XCTAssertEqual(viewController.view.backgroundColor, .systemBackground)
    }
}
