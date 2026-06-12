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

    func testLoadWeatherSetsLoadingState() {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather)
        )
        service.shouldSuspend = true
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)

        XCTAssertEqual(viewModel.state, .loading)
    }

    func testLoadWeatherCallsServiceWithProvidedCoordinates() async {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather)
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)

        viewModel.loadWeather(latitude: 52.52, longitude: 13.405)
        await waitUntilRequestCount(1, service: service)

        XCTAssertEqual(service.fetchCallCount, 1)
        XCTAssertEqual(service.receivedLatitude, 52.52)
        XCTAssertEqual(service.receivedLongitude, 13.405)
    }

    func testLoadWeatherSuccessSetsLoadedState() async {
        let service = WeatherFetchingSpy(
            result: .success(WeatherViewModelFixtures.berlinWeather)
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)
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
        let service = WeatherFetchingSpy(
            result: .failure(NetworkError.unauthorized)
        )
        let viewModel = LocationWeatherViewModel(weatherService: service)
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

    func testRefreshWithoutPreviousCoordinatesDoesNotCallService() async {
        let service = WeatherFetchingSpy()
        let viewModel = LocationWeatherViewModel(weatherService: service)
        var receivedStates: [LocationWeatherViewState] = []
        viewModel.onStateChange = { receivedStates.append($0) }

        viewModel.refresh()
        await Task.yield()

        XCTAssertEqual(viewModel.state, .idle)
        XCTAssertEqual(service.fetchCallCount, 0)
        XCTAssertTrue(receivedStates.isEmpty)
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
