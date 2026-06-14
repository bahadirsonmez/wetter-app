import Foundation

public enum LocationsListItemIdentifier: Hashable, Sendable {
    case current
    case saved(UUID)
}
