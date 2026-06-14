public struct LocationSearchResultViewData: Equatable, Sendable {

    public let title: String
    public let subtitle: String?

    public init(title: String, subtitle: String?) {
        self.title = title
        self.subtitle = subtitle
    }
}
