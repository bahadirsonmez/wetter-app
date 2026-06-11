import Foundation

public final class WeatherService: WeatherFetching {

    private let apiKey: String
    private let session: URLSession
    private let baseURL: String

    public init(
        apiKey: String,
        session: URLSession = .shared,
        baseURL: String = "https://api.openweathermap.org"
    ) {
        self.apiKey = apiKey
        self.session = session
        self.baseURL = baseURL
    }

    public func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        guard let url = makeCurrentWeatherURL(
            latitude: latitude,
            longitude: longitude
        ) else {
            throw NetworkError.invalidURL
        }

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(from: url)
        } catch {
            throw NetworkError.invalidResponse
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }

        if httpResponse.statusCode == 401 {
            throw NetworkError.unauthorized
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw NetworkError.invalidResponse
        }

        do {
            return try JSONDecoder().decode(CurrentWeather.self, from: data)
        } catch {
            throw NetworkError.decodingFailed
        }
    }

    private func makeCurrentWeatherURL(
        latitude: Double,
        longitude: Double
    ) -> URL? {
        guard
            var components = URLComponents(string: baseURL),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            components.host != nil
        else {
            return nil
        }

        components.path = "/data/2.5/weather"
        components.queryItems = [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude)),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]

        return components.url
    }
}
