/// Identifies whether a weather screen is driven by current location or a saved route.
public enum LocationWeatherSource: Equatable, Sendable {
    case current
    case saved(LocationWeatherRoute)
}
