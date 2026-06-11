public protocol WeatherServiceProvider: Sendable {

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather
}
