@testable import WeatherModel

struct WeatherFetchingMock: WeatherFetching {

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        throw NetworkError.invalidResponse
    }
}
