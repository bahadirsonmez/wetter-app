import WeatherViewModel

@MainActor
final class LocationWeatherViewModelSpy: LocationWeatherViewModeling {

    private(set) var state: LocationWeatherViewState = .idle
    var onStateChange: ((LocationWeatherViewState) -> Void)?

    private(set) var receivedLatitude: Double?
    private(set) var receivedLongitude: Double?
    private(set) var refreshCallCount = 0

    func loadWeather(latitude: Double, longitude: Double) {
        receivedLatitude = latitude
        receivedLongitude = longitude
    }

    func refresh() {
        refreshCallCount += 1
    }

    func send(_ state: LocationWeatherViewState) {
        self.state = state
        onStateChange?(state)
    }
}
