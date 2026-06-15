public enum LocationWeatherViewError: Equatable, Sendable {
    case unauthorized
    case unavailable
    case invalidData
    case unknown

    public var message: String {
        switch self {
        case .unauthorized:
            "Weather service authorization failed."
        case .unavailable:
            "Weather information is currently unavailable."
        case .invalidData:
            "Weather information could not be processed."
        case .unknown:
            "Something went wrong."
        }
    }
}
