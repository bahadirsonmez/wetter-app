public enum LocationsViewError: Equatable, Sendable {
    case persistenceFailed

    public var message: String {
        "Locations could not be saved."
    }
}
