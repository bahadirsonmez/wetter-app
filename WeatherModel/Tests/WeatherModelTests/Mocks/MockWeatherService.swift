import Foundation
@testable import WeatherModel

final class MockWeatherService: WeatherFetching, @unchecked Sendable {

    private let result: Result<CurrentWeather, NetworkError>

    init(json: String) {
        do {
            let weather = try JSONDecoder().decode(
                CurrentWeather.self,
                from: Data(json.utf8)
            )
            result = .success(weather)
        } catch {
            result = .failure(.decodingFailed)
        }
    }

    init(error: NetworkError) {
        result = .failure(error)
    }

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> CurrentWeather {
        try result.get()
    }

    func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> ForecastResponse {
        throw NetworkError.invalidResponse
    }
}
