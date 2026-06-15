/// Loads current weather and forecast state for a coordinate-based weather screen.
@MainActor
public protocol LocationWeatherViewModeling: AnyObject {

    var state: LocationWeatherViewState { get }
    var onStateChange: ((LocationWeatherViewState) -> Void)? { get set }

    /// Loads weather for the provided coordinate and stores it for future refreshes.
    func loadWeather(latitude: Double, longitude: Double)

    /// Reloads the last requested coordinate, bypassing local weather cache.
    func refresh()
}
