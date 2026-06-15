import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherStatusViewTests: XCTestCase {

    func testConfigureDisplaysContentAndAction() {
        let view = LocationWeatherStatusView()

        view.configure(
            title: "Weather unavailable",
            message: "Weather information is currently unavailable.",
            actionTitle: "Retry"
        )

        XCTAssertEqual(view.titleLabel.text, "Weather unavailable")
        XCTAssertEqual(
            view.messageLabel.text,
            "Weather information is currently unavailable."
        )
        XCTAssertEqual(view.actionButton.title(for: .normal), "Retry")
        XCTAssertFalse(view.actionButton.isHidden)
    }

    func testConfigureWithoutActionHidesButton() {
        let view = LocationWeatherStatusView()

        view.configure(
            title: "Location services disabled",
            message: "Enable Location Services to see local weather.",
            actionTitle: nil
        )

        XCTAssertNil(view.actionButton.title(for: .normal))
        XCTAssertTrue(view.actionButton.isHidden)
    }

    func testActionInvokesCallback() {
        let view = LocationWeatherStatusView()
        var actionCallCount = 0
        view.onAction = {
            actionCallCount += 1
        }

        view.actionButton.sendActions(for: .touchUpInside)

        XCTAssertEqual(actionCallCount, 1)
    }

    func testTextSupportsDynamicType() {
        let view = LocationWeatherStatusView()

        XCTAssertTrue(view.titleLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(view.messageLabel.adjustsFontForContentSizeCategory)
        XCTAssertTrue(
            view.actionButton.titleLabel?.adjustsFontForContentSizeCategory
                == true
        )
        XCTAssertEqual(view.titleLabel.numberOfLines, 0)
        XCTAssertEqual(view.messageLabel.numberOfLines, 0)
    }
}
