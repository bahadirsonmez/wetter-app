import XCTest
@testable import WeatherModel

final class LocationDetailsTests: XCTestCase {

    func testDecoding() throws {
        let locations = try JSONDecoder().decode(
            [LocationDetails].self,
            from: Data(WeatherModelFixtures.locationJSON.utf8)
        )
        let location = try XCTUnwrap(locations.first)

        XCTAssertEqual(location.name, "Berlin")
        XCTAssertEqual(location.localNames?["de"], "Berlin")
        XCTAssertEqual(location.countryCode, "DE")
        XCTAssertEqual(location.state, "Berlin")
    }
}
