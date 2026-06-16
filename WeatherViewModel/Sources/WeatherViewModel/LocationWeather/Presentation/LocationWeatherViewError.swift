public enum LocationWeatherViewError: Equatable, Sendable {
    case unauthorized
    case unavailable
    case invalidData
    case unknown
    case locationServicesDisabled
    case locationPermissionDenied
    case locationAccessRestricted
    case locationUnavailable

    public var title: String {
        switch self {
        case .unauthorized,
             .unavailable,
             .invalidData,
             .unknown:
            "Weather Unavailable"
        case .locationServicesDisabled:
            "Location Services Disabled"
        case .locationPermissionDenied:
            "Location Permission Required"
        case .locationAccessRestricted:
            "Location Access Restricted"
        case .locationUnavailable:
            "Location Unavailable"
        }
    }

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
        case .locationServicesDisabled:
            """
            Turn on Location Services to see weather for your current \
            location.
            """
        case .locationPermissionDenied:
            """
            Allow location access in Settings to see weather for your current \
            location.
            """
        case .locationAccessRestricted:
            "Location access is restricted on this device."
        case .locationUnavailable:
            "Your current location could not be determined."
        }
    }

    public var actionTitle: String? {
        switch self {
        case .locationServicesDisabled,
             .locationAccessRestricted:
            nil
        case .locationPermissionDenied:
            "Open Settings"
        case .unauthorized,
             .unavailable,
             .invalidData,
             .unknown,
             .locationUnavailable:
            "Retry"
        }
    }

    public var opensApplicationSettings: Bool {
        self == .locationPermissionDenied
    }
}
