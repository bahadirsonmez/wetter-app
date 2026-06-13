public protocol WeatherFetching: Sendable {

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather

    func fetchForecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResponse
}
