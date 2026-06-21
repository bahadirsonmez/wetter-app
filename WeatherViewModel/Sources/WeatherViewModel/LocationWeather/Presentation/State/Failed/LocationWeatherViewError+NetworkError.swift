import WeatherModel

extension LocationWeatherViewError {

    init(error: any Error) {
        guard let networkError = error as? NetworkError else {
            self = .unknown
            return
        }

        switch networkError {
        case .unauthorized:
            self = .unauthorized
        case .decodingFailed:
            self = .invalidData
        case .invalidURL, .invalidResponse:
            self = .unavailable
        }
    }
}
