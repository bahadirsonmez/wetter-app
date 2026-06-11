public protocol WeatherFetching: Sendable {

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather
}
