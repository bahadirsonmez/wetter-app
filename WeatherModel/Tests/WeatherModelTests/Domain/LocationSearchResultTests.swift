import XCTest
@testable import WeatherModel

final class LocationSearchResultTests: XCTestCase {

    func testInitializationPreservesLocationValues() {
        let result = LocationSearchResult(
            name: "Berlin",
            state: "Berlin",
            countryCode: "DE",
            latitude: 52.52,
            longitude: 13.405
        )

        XCTAssertEqual(result.name, "Berlin")
        XCTAssertEqual(result.state, "Berlin")
        XCTAssertEqual(result.countryCode, "DE")
        XCTAssertEqual(result.latitude, 52.52)
        XCTAssertEqual(result.longitude, 13.405)
    }
}
