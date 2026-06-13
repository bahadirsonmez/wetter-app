import Foundation
import XCTest
@testable import WeatherModel

final class ForecastWeatherServiceTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        URLProtocolStub.lastRequest = nil
        super.tearDown()
    }

    func testFetchForecastUsesExpectedPathAndCoordinates() async throws {
        stubResponse(
            statusCode: 200,
            data: Data(WeatherModelFixtures.forecastJSON.utf8)
        )

        _ = try await makeService().fetchForecast(
            latitude: 52.52,
            longitude: 13.405
        )

        XCTAssertEqual(
            URLProtocolStub.lastRequest?.url?.path,
            "/data/2.5/forecast"
        )
        XCTAssertEqual(queryValue(named: "lat"), "52.52")
        XCTAssertEqual(queryValue(named: "lon"), "13.405")
        XCTAssertEqual(queryValue(named: "appid"), "test-api-key")
        XCTAssertEqual(queryValue(named: "units"), "metric")
    }

    func testFetchForecastReturnsDecodedResponse() async throws {
        stubResponse(
            statusCode: 200,
            data: Data(WeatherModelFixtures.forecastJSON.utf8)
        )

        let response = try await makeService().fetchForecast(
            latitude: 52.52,
            longitude: 13.405
        )

        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response.location.name, "Berlin")
        XCTAssertEqual(
            response.forecasts.first?.timestampText,
            "2026-06-11 12:00:00"
        )
    }

    func testFetchForecastMapsUnauthorizedResponse() async {
        stubResponse(statusCode: 401)

        await assertFetchForecastThrows(.unauthorized)
    }

    func testFetchForecastMapsInvalidResponse() async {
        stubResponse(statusCode: 500)

        await assertFetchForecastThrows(.invalidResponse)
    }

    func testFetchForecastMapsDecodingFailure() async {
        stubResponse(
            statusCode: 200,
            data: Data("invalid-json".utf8)
        )

        await assertFetchForecastThrows(.decodingFailed)
    }

    // MARK: - Helpers

    private func makeService() -> WeatherService {
        WeatherService(
            apiKey: "test-api-key",
            session: makeSession()
        )
    }

    private func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [URLProtocolStub.self]
        return URLSession(configuration: configuration)
    }

    private func stubResponse(
        statusCode: Int,
        data: Data = Data()
    ) {
        URLProtocolStub.requestHandler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                )
            )

            return (response, data)
        }
    }

    private func assertFetchForecastThrows(
        _ expectedError: NetworkError
    ) async {
        do {
            _ = try await makeService().fetchForecast(
                latitude: 52.52,
                longitude: 13.405
            )
            XCTFail("Expected \(expectedError) to be thrown.")
        } catch let error as NetworkError {
            XCTAssertEqual(error, expectedError)
        } catch {
            XCTFail("Unexpected error: \(error)")
        }
    }

    private func queryValue(named name: String) -> String? {
        guard
            let url = URLProtocolStub.lastRequest?.url,
            let components = URLComponents(
                url: url,
                resolvingAgainstBaseURL: false
            )
        else {
            return nil
        }

        return components.queryItems?.first { $0.name == name }?.value
    }
}
