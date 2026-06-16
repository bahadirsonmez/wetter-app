/// Describes failures that can occur while requesting the user's current location.
public enum CurrentLocationError: Error, Equatable, Sendable {
    case servicesDisabled
    case authorizationDenied
    case authorizationRestricted
    case locationUnavailable
}
