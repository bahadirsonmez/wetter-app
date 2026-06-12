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

    func testLoadWeatherCallsServiceWithProvidedCoordinates() async {
        let (viewModel, service) = makeSUT()

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(1, service: service)

        XCTAssertEqual(service.fetchCallCount, 1)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
    }

    func testLoadWeatherSuccessSetsLoadedState() async {
        let (viewModel, _) = makeSUT()
        let expectedViewData = LocationWeatherViewData(
            weather: WeatherViewModelFixtures.berlinWeather
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

    func testRefreshUsesLastCoordinates() async {
        let (viewModel, service) = makeSUT()

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)
        viewModel.refresh()
        await waitUntilRequestCount(2, service: service)

        XCTAssertEqual(service.fetchCallCount, 2)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
    }

    func testRefreshWithoutPreviousCoordinatesDoesNotCallService() async {
        let (viewModel, service) = makeSUT()
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(service.fetchCallCount, 0)
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
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        service.result = .failure(NetworkError.unauthorized)
        service.shouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilFailed(viewModel)
        service.completeRequest(
            1,
            with: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            )
        )
        await Task.yield()

        XCTAssertFalse(receivedStates.contains { state in
            if case .loaded = state {
                return true
            }
            return false
        })
        XCTAssertEqual(viewModel.state, .failed(.unauthorized))
    }

    func testLatestRequestControlsFinalState() async {
        let (viewModel, service) = makeSUT(
            result: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            ),
            shouldSuspend: true,
            ignoresCancellation: true
        )

        viewModel.loadWeather(latitude: 1, longitude: 1)
        await waitUntilRequestCount(1, service: service)
        service.result = .success(WeatherViewModelFixtures.berlinWeather)
        service.shouldSuspend = false
        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilLoaded(viewModel)
        service.completeRequest(
            1,
            with: .success(
                WeatherViewModelFixtures.weather(locationName: "Old")
            )
        )
        await Task.yield()

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

    private func makeSUT(
        result: Result<CurrentWeather, Error> = .success(
            WeatherViewModelFixtures.berlinWeather
        ),
        shouldSuspend: Bool = false,
        ignoresCancellation: Bool = false
    ) -> (LocationWeatherViewModel, WeatherFetchingSpy) {
        let service = WeatherFetchingSpy(result: result)
        service.shouldSuspend = shouldSuspend
        service.ignoresCancellation = ignoresCancellation

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
        for _ in 0..<100 {
            if condition() {
                return
            }
            await Task.yield()
        }
        XCTFail(failureMessage)
    }
}
