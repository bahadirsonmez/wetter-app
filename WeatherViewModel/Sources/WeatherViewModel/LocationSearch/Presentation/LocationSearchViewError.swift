public enum LocationSearchViewError: Equatable, Sendable {

    case unavailable
    case persistenceFailed
    case unknown

    public var message: String {
        switch self {
        case .unavailable:
            return "Location search is currently unavailable."
        case .persistenceFailed:
            return "The location could not be saved."
        case .unknown:
            return "Something went wrong."
        }
    }
}
