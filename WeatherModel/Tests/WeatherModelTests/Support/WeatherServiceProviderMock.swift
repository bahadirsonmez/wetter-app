@testable import WeatherModel

struct WeatherServiceProviderMock: WeatherServiceProvider {

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        throw NetworkError.invalidResponse
    }
}
