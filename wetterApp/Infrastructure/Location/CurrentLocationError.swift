enum CurrentLocationError: Error, Equatable {
    case servicesDisabled
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable
}
