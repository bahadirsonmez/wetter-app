import WeatherModel

extension LocationWeatherViewError {

    init(error: CurrentLocationError) {
        switch error {
        case .servicesDisabled:
            self = .locationServicesDisabled
        case .authorizationDenied:
            self = .locationPermissionDenied
        case .authorizationRestricted:
            self = .locationAccessRestricted
        case .locationUnavailable:
            self = .locationUnavailable
        }
    }
}
