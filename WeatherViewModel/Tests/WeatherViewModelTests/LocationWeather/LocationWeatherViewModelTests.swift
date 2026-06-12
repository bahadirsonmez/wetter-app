import XCTest
import WeatherModel
@testable import WeatherViewModel

@MainActor
final class LocationWeatherViewModelTests: XCTestCase {

    func testInitialStateIsIdle() {
        let viewModel = LocationWeatherViewModel(
            weatherService: WeatherFetchingSpy()
        )

        XCTAssertEqual(viewModel.state, .idle)
    }

    func testLoadWeatherPublishesLoadingThenFormattedData() async {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather)
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
        XCTAssertEqual(service.fetchCallCount, 1)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
    }

    func testRefreshUsesPreviouslyLoadedCoordinates() async {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather)
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)
        viewModel.refresh()
        await waitUntilRequestCount(2, service: service)

        XCTAssertEqual(service.fetchCallCount, 2)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
    }

    func testLoadWeatherPreservesMissingCondition() async {
        let service = WeatherFetchingSpy(
            result: .success(
                WeatherViewModelFixtures.weatherWithoutCondition
            )
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }

        XCTAssertNil(viewData.conditionText)
        XCTAssertNil(viewData.conditionIconName)
    }

    func testRefreshWithoutCoordinatesDoesNothing() async {
        let service = WeatherFetchingSpy()
        let viewModel = LocationWeatherViewModel(weatherService: service)
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertTrue(receivedStates.isEmpty)
        XCTAssertEqual(service.fetchCallCount, 0)
    }

    func testLoadWeatherMapsNetworkErrorsToViewErrors() async {
        let mappings: [(NetworkError, LocationWeatherViewError)] = [
            (.unauthorized, .unauthorized),
            (.invalidResponse, .unavailable),
            (.decodingFailed, .invalidData),
            (.invalidURL, .unavailable)
        ]

        for (networkError, expectedViewError) in mappings {
            let service = WeatherFetchingSpy(
                result: .failure(networkError)
            )
            let viewModel = LocationWeatherViewModel(
                weatherService: service
            )

            viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
            await waitUntilFailed(viewModel)

            XCTAssertEqual(viewModel.state, .failed(expectedViewError))
        }
    }

    func testNewLoadCancelsPreviousRequest() async {
        let service = WeatherFetchingSpy(
            result: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            )
        )
        service.shouldSuspend = true
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        service.result = .success(WeatherViewModelFixtures.berlinWeather)
        service.shouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }
        XCTAssertEqual(viewData.locationName, "Berlin")
    }

    func testDeinitCancelsCurrentTask() async {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather)
        )
        service.shouldSuspend = true
        var viewModel: LocationWeatherViewModel? = LocationWeatherViewModel(
            weatherService: service
        )
        weak let weakViewModel = viewModel

        viewModel?.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(1, service: service)
        viewModel = nil
        await waitUntilCancellationCount(1, service: service)

        XCTAssertNil(weakViewModel)
        XCTAssertEqual(service.cancellationCount, 1)
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
        service: WeatherFetchingSpy
    ) async {
        for _ in 0..<100 {
            if service.fetchCallCount == count {
                return
            }
            await Task.yield()
        }
        XCTFail("Expected \(count) requests.")
    }

    private func waitUntilCancellationCount(
        _ count: Int,
        service: WeatherFetchingSpy
    ) async {
        for _ in 0..<100 {
            if service.cancellationCount == count {
                return
            }
            await Task.yield()
        }
        XCTFail("Expected \(count) cancellations.")
    }
}
