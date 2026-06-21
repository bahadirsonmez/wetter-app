/// Defines the network operations required for fetching weather data.
public protocol WeatherFetching: Sendable {

    /// Fetches the current weather conditions for a given coordinate.
    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> CurrentWeather

    /// Fetches the hourly forecast for a given coordinate.
    func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> ForecastResponse
}

public extension WeatherFetching {

    /// Fetches the current weather conditions, using cache if available.
    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        try await fetchCurrentWeather(
            latitude: latitude,
            longitude: longitude,
            forceRefresh: false
        )
    }

    /// Fetches the hourly forecast, using cache if available.
    func fetchForecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResponse {
        try await fetchForecast(
            latitude: latitude,
            longitude: longitude,
            forceRefresh: false
        )
    }
}
