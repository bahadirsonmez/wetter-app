import XCTest
import WeatherModel
@testable import WeatherViewModel

@MainActor
final class LocationWeatherViewModelTests: XCTestCase {

    func testInitialStateIsIdle() {
        let (viewModel, _) = makeSUT()

        XCTAssertEqual(viewModel.state, .idle)
    }

    func testLoadWeatherSetsLoadingState() {
        let (viewModel, _) = makeSUT(
            shouldSuspend: true
        )

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)

        XCTAssertEqual(viewModel.state, .loading)
    }

    func testLoadWeatherRequestsCurrentWeatherAndForecast() async {
        let (viewModel, service) = makeSUT()

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(1, service: service)
        await waitUntilForecastRequestCount(1, service: service)

        XCTAssertEqual(service.fetchCallCount, 1)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
        XCTAssertEqual(service.forecastFetchCallCount, 1)
        XCTAssertEqual(service.forecastReceivedLatitude, 52.52)
        XCTAssertEqual(service.forecastReceivedLongitude, 13.405)
    }

    func testLoadWeatherSuccessSetsLoadedState() async {
        let (viewModel, _) = makeSUT()
        let hourlyForecast = ForecastViewDataMapper().map(
            WeatherViewModelFixtures.forecastResponse()
        )
        let expectedViewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.berlinWeather,
            hourlyForecast: hourlyForecast,
            formatter: LocationWeatherFormatter()
        )
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        XCTAssertEqual(viewModel.state, .loaded(expectedViewData))
        XCTAssertEqual(
            receivedStates,
            [.loading, .loaded(expectedViewData)]
        )
    }

    func testLoadWeatherMapsForecastIntoLoadedState() async {
        let forecast = WeatherViewModelFixtures.forecastResponse(
            samples: [
                (1_781_355_600, 24.4, "moderate rain"),
                (1_781_366_400, 27.6, "clear sky")
            ]
        )
        let (viewModel, _) = makeSUT(forecastResult: .success(forecast))

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }

        XCTAssertEqual(viewData.hourlyForecast.days.count, 1)
        XCTAssertEqual(
            viewData.hourlyForecast.days[0].items.map(\.temperatureText),
            ["24°C", "28°C"]
        )
        XCTAssertEqual(viewData.hourlyForecast.minimumTemperature, 24.4)
        XCTAssertEqual(viewData.hourlyForecast.maximumTemperature, 27.6)
    }

    func testLoadWeatherFailureSetsFailedState() async {
        let (viewModel, _) = makeSUT(
            result: .failure(NetworkError.unauthorized)
        )
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilFailed(viewModel)

        XCTAssertEqual(viewModel.state, .failed(.unauthorized))
        XCTAssertEqual(
            receivedStates,
            [.loading, .failed(.unauthorized)]
        )
    }

    func testForecastFailureProducesFailedState() async {
        let (viewModel, _) = makeSUT(
            forecastResult: .failure(NetworkError.decodingFailed)
        )

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilFailed(viewModel)

        XCTAssertEqual(viewModel.state, .failed(.invalidData))
    }

    func testRefreshReloadsBothResources() async {
        let (viewModel, service) = makeSUT()

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)
        viewModel.refresh()
        await waitUntilRequestCount(2, service: service)
        await waitUntilForecastRequestCount(2, service: service)

        XCTAssertEqual(service.fetchCallCount, 2)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
        XCTAssertEqual(service.forecastFetchCallCount, 2)
        XCTAssertEqual(service.forecastReceivedLatitude, 52.52)
        XCTAssertEqual(service.forecastReceivedLongitude, 13.405)
    }

    func testRefreshWithoutPreviousCoordinatesDoesNotCallService() async {
        let (viewModel, service) = makeSUT()
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(service.fetchCallCount, 0)
        XCTAssertEqual(service.forecastFetchCallCount, 0)
        XCTAssertTrue(receivedStates.isEmpty)
    }

    func testLoadWeatherWhenCalledAgainCancelsPreviousRequest() async {
        let (viewModel, service) = makeSUT(
            shouldSuspend: true
        )

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        service.shouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilCancellationCount(1, service: service)

        XCTAssertEqual(service.cancellationCount, 1)
    }

    func testCancelledRequestDoesNotPublishLoadedState() async {
        let (viewModel, service) = makeSUT(
            result: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            ),
            shouldSuspend: true,
            ignoresCancellation: true
        )
        var receivedStates: [LocationWeatherViewState] = []
        let loadedStateExpectation = expectation(
            description: "Cancelled request does not publish loaded state."
        )
        loadedStateExpectation.isInverted = true
        viewModel.onStateChange = { state in
            receivedStates.append(state)
            if case .loaded = state {
                loadedStateExpectation.fulfill()
            }
        }

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        service.result = .failure(NetworkError.unauthorized)
        service.shouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(2, service: service)
        await waitUntilFailed(viewModel)
        service.completeRequest(
            1,
            with: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            )
        )
        await fulfillment(of: [loadedStateExpectation], timeout: 0.2)

        XCTAssertFalse(receivedStates.contains { state in
            if case .loaded = state {
                return true
            }
            return false
        })
        XCTAssertEqual(viewModel.state, .failed(.unauthorized))
    }

    func testCancelledLoadDoesNotPublishForecast() async {
        let staleForecast = WeatherViewModelFixtures.forecastResponse(
            samples: [(1_781_355_600, 10, "clear sky")]
        )
        let latestForecast = WeatherViewModelFixtures.forecastResponse(
            samples: [(1_781_355_600, 30, "clear sky")]
        )
        let (viewModel, service) = makeSUT(
            forecastResult: .success(staleForecast),
            forecastShouldSuspend: true,
            forecastIgnoresCancellation: true
        )
        let staleForecastExpectation = expectation(
            description: "Cancelled load does not publish stale forecast."
        )
        staleForecastExpectation.isInverted = true
        viewModel.onStateChange = { state in
            guard
                case let .loaded(viewData) = state,
                viewData.hourlyForecast.minimumTemperature == 10
            else {
                return
            }
            staleForecastExpectation.fulfill()
        }

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilForecastRequestCount(1, service: service)
        service.forecastResult = .success(latestForecast)
        service.forecastShouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilForecastRequestCount(2, service: service)
        await waitUntilLoaded(viewModel)
        service.completeForecastRequest(1, with: .success(staleForecast))
        await fulfillment(of: [staleForecastExpectation], timeout: 0.2)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }

        XCTAssertEqual(viewData.hourlyForecast.minimumTemperature, 30)
    }

    func testLatestRequestControlsFinalState() async {
        let (viewModel, service) = makeSUT(
            result: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            ),
            shouldSuspend: true,
            ignoresCancellation: true
        )
        let staleStateExpectation = expectation(
            description: "Stale request does not control final state."
        )
        staleStateExpectation.isInverted = true
        viewModel.onStateChange = { state in
            guard case let .loaded(viewData) = state,
                  viewData.locationName == "Old" else {
                return
            }
            staleStateExpectation.fulfill()
        }

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        service.result = .success(WeatherViewModelFixtures.berlinWeather)
        service.shouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(2, service: service)
        await waitUntilLoaded(viewModel)
        service.completeRequest(
            1,
            with: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            )
        )
        await fulfillment(of: [staleStateExpectation], timeout: 0.2)

        guard case let .loaded(viewData) = viewModel.state else {
            return XCTFail("Expected loaded state.")
        }

        XCTAssertEqual(viewData.locationName, "Berlin")
    }

    func testDeinitCancelsCurrentTask() async {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather),
            forecastResult: .success(
                WeatherViewModelFixtures.forecastResponse()
            )
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

    private func makeSUT(
        result: Result<CurrentWeather, Error> = .success(
            WeatherViewModelFixtures.berlinWeather
        ),
        forecastResult: Result<ForecastResponse, Error> = .success(
            WeatherViewModelFixtures.forecastResponse()
        ),
        shouldSuspend: Bool = false,
        ignoresCancellation: Bool = false,
        forecastShouldSuspend: Bool = false,
        forecastIgnoresCancellation: Bool = false
    ) -> (LocationWeatherViewModel, WeatherFetchingSpy) {
        let service = WeatherFetchingSpy(
            result: result,
            forecastResult: forecastResult
        )
        service.shouldSuspend = shouldSuspend
        service.ignoresCancellation = ignoresCancellation
        service.forecastShouldSuspend = forecastShouldSuspend
        service.forecastIgnoresCancellation = forecastIgnoresCancellation

        return (
            LocationWeatherViewModel(weatherService: service),
            service
        )
    }

    private func waitUntilLoaded(
        _ viewModel: LocationWeatherViewModel
    ) async {
        await waitUntil(
            condition: {
                if case .loaded = viewModel.state {
                    return true
                }
                return false
            },
            failureMessage: "Expected loaded state."
        )
    }

    private func waitUntilFailed(
        _ viewModel: LocationWeatherViewModel
    ) async {
        await waitUntil(
            condition: {
                if case .failed = viewModel.state {
                    return true
                }
                return false
            },
            failureMessage: "Expected failed state."
        )
    }

    private func waitUntilRequestCount(
        _ count: Int,
        service: WeatherFetchingSpy
    ) async {
        await waitUntil(
            condition: { service.fetchCallCount == count },
            failureMessage: "Expected \(count) requests."
        )
    }

    private func waitUntilForecastRequestCount(
        _ count: Int,
        service: WeatherFetchingSpy
    ) async {
        await waitUntil(
            condition: { service.forecastFetchCallCount == count },
            failureMessage: "Expected \(count) forecast requests."
        )
    }

    private func waitUntilCancellationCount(
        _ count: Int,
        service: WeatherFetchingSpy
    ) async {
        await waitUntil(
            condition: { service.cancellationCount == count },
            failureMessage: "Expected \(count) cancellations."
        )
    }

    private func waitUntil(
        condition: () -> Bool,
        failureMessage: String
    ) async {
        let clock = ContinuousClock()
        let deadline = clock.now + .seconds(1)

        while clock.now < deadline {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail(failureMessage)
    }
}
