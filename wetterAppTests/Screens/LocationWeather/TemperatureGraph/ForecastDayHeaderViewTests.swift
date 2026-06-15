import XCTest
@testable import wetterApp

@MainActor
final class ForecastDayHeaderViewTests: XCTestCase {

    func testElementKindUsesForecastDayHeaderIdentifier() {
        XCTAssertEqual(
            ForecastDayHeaderView.elementKind,
            "ForecastDayHeader"
        )
    }

    func testConfigureSetsTitle() {
        let view = ForecastDayHeaderView()

        view.configure(title: "Saturday, Jun 13")

        XCTAssertEqual(view.titleLabel.text, "Saturday, Jun 13")
    }

    func testPrepareForReuseClearsTitle() {
        let view = ForecastDayHeaderView()
        view.configure(title: "Saturday, Jun 13")

        view.prepareForReuse()

        XCTAssertNil(view.titleLabel.text)
    }
}
