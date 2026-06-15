public protocol WeatherFetching: Sendable {

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> CurrentWeather

    func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> ForecastResponse
}

public extension WeatherFetching {

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
