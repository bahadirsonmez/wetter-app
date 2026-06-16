import WeatherViewModel

@MainActor
final class LocationWeatherViewModelSpy: LocationWeatherViewModeling {

    let source: LocationWeatherSource
    private(set) var state: LocationWeatherViewState = .idle
    var onStateChange: ((LocationWeatherViewState) -> Void)?

    private(set) var loadInitialWeatherCallCount = 0
    private(set) var refreshCallCount = 0
    private(set) var requestCurrentLocationAfterActivationCallCount = 0

    init(source: LocationWeatherSource = .current) {
        self.source = source
    }

    func loadInitialWeather() {
        loadInitialWeatherCallCount += 1
    }

    func refresh() {
        refreshCallCount += 1
    }

    func requestCurrentLocationAfterActivation() {
        requestCurrentLocationAfterActivationCallCount += 1
    }

    func send(_ state: LocationWeatherViewState) {
        self.state = state
        onStateChange?(state)
    }
}
