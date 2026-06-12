import XCTest
import WeatherModel
@testable import WeatherViewModel

@MainActor
final class LocationWeatherViewModelTests: XCTestCase {

    func testInitialStateIsIdle() {
        let viewModel = LocationWeatherViewModel(
            weatherService: MockWeatherService()
        )

        XCTAssertEqual(viewModel.state, .idle)
    }

    func testLoadWeatherPublishesLoadingThenFormattedData() async throws {
        let service = MockWeatherService(
            results: [.success(try makeCurrentWeather())]
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        XCTAssertEqual(
            receivedStates,
            [
                .loading,
                .loaded(
                    LocationWeatherViewData(
                        locationName: "Berlin",
                        countryCode: "DE",
                        temperatureText: "24°C",
                        feelsLikeText: "Feels like 25°C",
                        humidityText: "64%",
                        conditionText: "Moderate rain",
                        conditionIconName: "10d"
                    )
                )
            ]
        )
        let requests = await service.requests
        XCTAssertEqual(requests, [.init(latitude: 52.52, longitude: 13.405)])
    }

    func testRefreshUsesPreviouslyLoadedCoordinates() async throws {
        let weather = try makeCurrentWeather()
        let service = MockWeatherService(
            results: [.success(weather), .success(weather)]
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)
        viewModel.refresh()
        await waitUntilRequestCount(2, service: service)

        let requests = await service.requests
        XCTAssertEqual(
            requests,
            [
                .init(latitude: 52.52, longitude: 13.405),
                .init(latitude: 52.52, longitude: 13.405)
            ]
        )
    }

    func testLoadWeatherAppliesMissingValueFallbacks() async throws {
        let service = MockWeatherService(
            results: [
                .success(
                    try makeCurrentWeather(
                        countryCode: nil,
                        includesCondition: false
                    )
                )
            ]
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }

        XCTAssertNil(viewData.countryCode)
        XCTAssertEqual(viewData.conditionText, "Unknown")
        XCTAssertNil(viewData.conditionIconName)
    }

    func testRefreshWithoutCoordinatesDoesNothing() async {
        let service = MockWeatherService()
        let viewModel = LocationWeatherViewModel(weatherService: service)
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(receivedStates.isEmpty)
        let requests = await service.requests
        XCTAssertTrue(requests.isEmpty)
    }

    func testLoadWeatherMapsNetworkErrorsToViewErrors() async {
        let mappings: [(NetworkError, LocationWeatherViewError)] = [
            (.unauthorized, .unauthorized),
            (.invalidResponse, .unavailable),
            (.decodingFailed, .invalidData),
            (.invalidURL, .unknown)
        ]

        for (networkError, expectedViewError) in mappings {
            let service = MockWeatherService(
                results: [.failure(networkError)]
            )
            let viewModel = LocationWeatherViewModel(
                weatherService: service
            )

            viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
            await waitUntilFailed(viewModel)

            XCTAssertEqual(viewModel.state, .failed(expectedViewError))
        }
    }

    func testNewLoadCancelsPreviousRequest() async throws {
        let service = MockWeatherService(
            results: [
                .success(try makeCurrentWeather(locationName: "Old")),
                .success(try makeCurrentWeather(locationName: "Berlin"))
            ],
            delays: [500_000_000, 0]
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }
        XCTAssertEqual(viewData.locationName, "Berlin")
    }

    func testDeinitCancelsCurrentTask() async throws {
        let service = MockWeatherService(
            results: [.success(try makeCurrentWeather())],
            delays: [500_000_000]
        )
        var viewModel: LocationWeatherViewModel? = LocationWeatherViewModel(
            weatherService: service
        )
        weak let weakViewModel = viewModel

        viewModel?.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(1, service: service)
        viewModel = nil
        await waitUntilCancellationCount(1, service: service)
        let cancellationCount = await service.cancellationCount

        XCTAssertNil(weakViewModel)
        XCTAssertEqual(cancellationCount, 1)
    }

    private func waitUntilLoaded(
        _ viewModel: LocationWeatherViewModel
    ) async {
        for _ in 0..<100 {
            if case .loaded = viewModel.state {
                return
            }
            await Task.yield()
        }
        XCTFail("Expected loaded state.")
    }

    private func waitUntilFailed(
        _ viewModel: LocationWeatherViewModel
    ) async {
        for _ in 0..<100 {
            if case .failed = viewModel.state {
                return
            }
            await Task.yield()
        }
        XCTFail("Expected failed state.")
    }

    private func waitUntilRequestCount(
        _ count: Int,
        service: MockWeatherService
    ) async {
        for _ in 0..<100 {
            if await service.requests.count == count {
                return
            }
            await Task.yield()
        }
        XCTFail("Expected \(count) requests.")
    }

    private func waitUntilCancellationCount(
        _ count: Int,
        service: MockWeatherService
    ) async {
        for _ in 0..<100 {
            if await service.cancellationCount == count {
                return
            }
            await Task.yield()
        }
        XCTFail("Expected \(count) cancellations.")
    }
}
