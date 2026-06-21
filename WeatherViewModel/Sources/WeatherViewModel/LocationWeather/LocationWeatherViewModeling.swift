/// Loads current weather and forecast state for a coordinate-based weather screen.
@MainActor
public protocol LocationWeatherViewModeling: AnyObject {

    var source: LocationWeatherSource { get }
    var state: LocationWeatherViewState { get }
    var onStateChange: ((LocationWeatherViewState) -> Void)? { get set }

    /// Starts the first weather load for the configured source.
    func loadInitialWeather()

    /// Reloads the last requested coordinate, bypassing local weather cache.
    func refresh()

    /// Requests a new current-location lookup when the app becomes active again.
    func requestCurrentLocationAfterActivation()
}
