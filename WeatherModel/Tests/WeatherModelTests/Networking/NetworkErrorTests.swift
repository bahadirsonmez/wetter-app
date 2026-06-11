import XCTest
@testable import WeatherModel

final class NetworkErrorTests: XCTestCase {

    func testCasesAreDistinct() {
        XCTAssertNotEqual(NetworkError.invalidURL, .invalidResponse)
        XCTAssertNotEqual(NetworkError.invalidResponse, .decodingFailed)
        XCTAssertNotEqual(NetworkError.decodingFailed, .unauthorized)
    }
}
