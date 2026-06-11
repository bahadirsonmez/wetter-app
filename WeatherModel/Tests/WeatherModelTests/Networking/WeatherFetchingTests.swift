import XCTest
@testable import WeatherModel

final class WeatherFetchingTests: XCTestCase {

    func testProviderCanBeMocked() async {
        let service: any WeatherFetching = WeatherFetchingMock()

        do {
            _ = try await service.fetchCurrentWeather(
                latitude: 52.52,
                longitude: 13.405
            )
            XCTFail("Expected the mock service to throw.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, .invalidResponse)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }
}
