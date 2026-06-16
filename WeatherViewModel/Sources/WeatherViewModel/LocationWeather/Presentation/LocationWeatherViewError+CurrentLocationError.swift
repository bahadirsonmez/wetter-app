import WeatherModel

extension LocationWeatherViewError {

    init(error: CurrentLocationError) {
        switch error {
        case .servicesDisabled:
            self = .locationServicesDisabled
        case .authorizationDenied:
            self = .locationPermissionRequired
        case .authorizationRestricted:
            self = .locationAccessRestricted
        case .locationUnavailable:
            self = .locationUnavailable
        }
    }
}
