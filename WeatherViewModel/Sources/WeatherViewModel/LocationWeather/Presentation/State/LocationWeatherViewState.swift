public enum LocationWeatherViewState: Equatable, Sendable {
    case idle
    case loading
    case loaded(LocationWeatherViewData)
    case failed(LocationWeatherViewError)
}
