import XCTest
@testable import WeatherViewModel

final class WeatherCoordinatesTests: XCTestCase {

    func testCoordinatesWithEqualValuesAreEqual() {
        let coordinates = WeatherCoordinates(
            latitude: 52.52,
            longitude: 13.405
        )

        XCTAssertEqual(
            coordinates,
            WeatherCoordinates(latitude: 52.52, longitude: 13.405)
        )
    }
}
