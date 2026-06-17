import Foundation
import XCTest
@testable import WeatherModel

final class WeatherServiceTests: XCTestCase {

    override func tearDown() {
        URLProtocolStub.requestHandler = nil
        URLProtocolStub.lastRequest = nil
        super.tearDown()
    }

    func testFetchCurrentWeatherReturnsDecodedModelForSuccessfulResponse() async throws {
        URLProtocolStub.requestHandler = { request in
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )

            return (
                response,
                Data(WeatherModelFixtures.currentWeatherJSON.utf8)
            )
        }

        let weather = try await makeService().fetchCurrentWeather(
            latitude: 52.52,
            longitude: 13.405
        )

        XCTAssertEqual(weather.locationName, "Berlin")
        XCTAssertEqual(URLProtocolStub.lastRequest?.url?.host, "api.openweathermap.org")
        XCTAssertEqual(queryValue(named: "lat"), "52.52")
        XCTAssertEqual(queryValue(named: "lon"), "13.405")
        XCTAssertEqual(queryValue(named: "appid"), "test-api-key")
        XCTAssertEqual(queryValue(named: "units"), "metric")
    }

    func testFetchCurrentWeatherThrowsUnauthorizedFor401Response() async {
        stubResponse(statusCode: 401)

        await assertFetchThrows(.unauthorized)
    }

    func testFetchCurrentWeatherThrowsInvalidResponseForUnsuccessfulResponse() async {
        stubResponse(statusCode: 500)

        await assertFetchThrows(.invalidResponse)
    }

    func testFetchCurrentWeatherThrowsInvalidResponseForTransportError() async {
        URLProtocolStub.requestHandler = { _ in
            throw URLError(.notConnectedToInternet)
        }

        await assertFetchThrows(.invalidResponse)
    }

    func testFetchCurrentWeatherThrowsDecodingFailedForInvalidJSON() async {
        stubResponse(
            statusCode: 200,
            data: Data("invalid-json".utf8)
        )

        await assertFetchThrows(.decodingFailed)
    }

    func testFetchCurrentWeatherThrowsInvalidURLForMalformedBaseURL() async {
        let service = WeatherService(
            apiKey: "test-api-key",
            session: makeSession(),
            baseURL: "://"
        )

        await assertFetchThrows(.invalidURL, using: service)
    }

    func testFetchCurrentWeatherCachesResponse() async throws {
        var requestCount = 0
        URLProtocolStub.requestHandler = { request in
            requestCount += 1
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (response, Data(WeatherModelFixtures.currentWeatherJSON.utf8))
        }

        let service = makeService()

        _ = try await service.fetchCurrentWeather(
            latitude: 52.52,
            longitude: 13.405
        )
        XCTAssertEqual(requestCount, 1)

        _ = try await service.fetchCurrentWeather(
            latitude: 52.52,
            longitude: 13.405
        )
        XCTAssertEqual(
            requestCount,
            1,
            "Should use cached response without triggering a network request"
        )
    }

    func testForceRefreshBypassesCachedResponse() async throws {
        var requestCount = 0
        URLProtocolStub.requestHandler = { request in
            requestCount += 1
            let response = try XCTUnwrap(
                HTTPURLResponse(
                    url: try XCTUnwrap(request.url),
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )
            )
            return (
                response,
                Data(WeatherModelFixtures.currentWeatherJSON.utf8)
            )
        }

        let service = makeService()
        _ = try await service.fetchCurrentWeather(
            latitude: 52.52,
            longitude: 13.405
        )
        _ = try await service.fetchCurrentWeather(
            latitude: 52.52,
            longitude: 13.405,
            forceRefresh: true
        )

        XCTAssertEqual(requestCount, 2)
        XCTAssertEqual(
            URLProtocolStub.lastRequest?.cachePolicy,
            .reloadIgnoringLocalCacheData
        )
    }

    func testDataCacheStoresAndRetrievesData() async {
        let cache = DataCache()
        let data = Data("test".utf8)
        await cache.set(data, for: "key")

        let retrieved = await cache.get(for: "key")
        XCTAssertEqual(retrieved, data)
    }

    func testDataCacheExpiresData() async {
        var currentDate = Date(timeIntervalSince1970: 0)
        let cache = DataCache(maxAge: 300, dateProvider: { currentDate })
        let data = Data("test".utf8)

        await cache.set(data, for: "key")

        // advance time by 6 minutes (360 seconds)
        currentDate = currentDate.addingTimeInterval(360)

        let retrieved = await cache.get(for: "key")
        XCTAssertNil(retrieved)
    }

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

    private func assertFetchThrows(
        _ expectedError: NetworkError,
        using service: WeatherService? = nil
    ) async {
        do {
            _ = try await (service ?? makeService()).fetchCurrentWeather(
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
