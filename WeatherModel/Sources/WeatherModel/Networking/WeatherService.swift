import Foundation

public final class WeatherService: WeatherFetching {

    private let apiKey: String
    private let session: URLSession
    private let baseURL: String

    private let cache = DataCache()
    private let cacheMaxAge: TimeInterval = 300 // 5 minutes

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
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> CurrentWeather {
        try await performRequest(
            path: "/data/2.5/weather",
            queryItems: coordinateQueryItems(
                latitude: latitude,
                longitude: longitude
            ),
            forceRefresh: forceRefresh
        )
    }

    public func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> ForecastResponse {
        try await performRequest(
            path: "/data/2.5/forecast",
            queryItems: coordinateQueryItems(
                latitude: latitude,
                longitude: longitude
            ),
            forceRefresh: forceRefresh
        )
    }

    private func performRequest<Response: Decodable>(
        path: String,
        queryItems: [URLQueryItem],
        forceRefresh: Bool
    ) async throws -> Response {
        guard let url = makeURL(path: path, queryItems: queryItems) else {
            throw NetworkError.invalidURL
        }

        let cacheKey = url.absoluteString
        if !forceRefresh,
           let cachedData = await cache.get(
               for: cacheKey,
               maxAge: cacheMaxAge
           ) {
            do {
                return try JSONDecoder().decode(Response.self, from: cachedData)
            } catch {
                // Ignore decoding error from cache and fetch fresh
            }
        }

        do {
            let cachePolicy: URLRequest.CachePolicy = forceRefresh
                ? .reloadIgnoringLocalCacheData
                : .useProtocolCachePolicy
            let request = URLRequest(
                url: url,
                cachePolicy: cachePolicy
            )
            let (data, response) = try await session.data(for: request)

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
                let decoded = try JSONDecoder().decode(Response.self, from: data)
                await cache.set(data, for: cacheKey)
                return decoded
            } catch {
                throw NetworkError.decodingFailed
            }
        } catch let error as NetworkError {
            throw error
        } catch {
            throw NetworkError.invalidResponse
        }
    }

    private func coordinateQueryItems(
        latitude: Double,
        longitude: Double
    ) -> [URLQueryItem] {
        [
            URLQueryItem(name: "lat", value: String(latitude)),
            URLQueryItem(name: "lon", value: String(longitude))
        ]
    }

    private func makeURL(
        path: String,
        queryItems: [URLQueryItem]
    ) -> URL? {
        guard
            var components = URLComponents(string: baseURL),
            let scheme = components.scheme?.lowercased(),
            ["http", "https"].contains(scheme),
            components.host != nil
        else {
            return nil
        }

        components.path = path
        components.queryItems = queryItems + [
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]

        return components.url
    }
}
