public struct LocationsListItemViewData: Equatable, Sendable {

    public let identifier: LocationsListItemIdentifier
    public let title: String
    public let subtitle: String?
    public let isDeletable: Bool
    public let isMovable: Bool

    public init(
        identifier: LocationsListItemIdentifier,
        title: String,
        subtitle: String?,
        isDeletable: Bool,
        isMovable: Bool
    ) {
        self.identifier = identifier
        self.title = title
        self.subtitle = subtitle
        self.isDeletable = isDeletable
        self.isMovable = isMovable
    }
}
