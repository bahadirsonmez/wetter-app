import Foundation
import WeatherModel

actor MockWeatherService: WeatherFetching {

    struct Request: Equatable {
        let latitude: Double
        let longitude: Double
    }

    private(set) var requests: [Request] = []
    private var results: [Result<CurrentWeather, NetworkError>]
    private var delays: [UInt64]

    init(
        results: [Result<CurrentWeather, NetworkError>] = [],
        delays: [UInt64] = []
    ) {
        self.results = results
        self.delays = delays
    }

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        requests.append(
            Request(latitude: latitude, longitude: longitude)
        )

        guard !results.isEmpty else {
            throw NetworkError.invalidResponse
        }

        let result = results.removeFirst()

        if !delays.isEmpty {
            try await Task.sleep(nanoseconds: delays.removeFirst())
        }

        return try result.get()
    }
}
