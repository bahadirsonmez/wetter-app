@MainActor
public protocol LocationWeatherViewModeling: AnyObject {

    var state: LocationWeatherViewState { get }
    var onStateChange: ((LocationWeatherViewState) -> Void)? { get set }

    func loadWeather(latitude: Double, longitude: Double)
    func refresh()
}
