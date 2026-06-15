public struct WeatherTileViewData: Equatable, Sendable {

    public let id: WeatherTileIdentifier
    public let title: String
    public let valueText: String
    public let detailText: String?
    public let symbolName: String

    public init(
        id: WeatherTileIdentifier,
        title: String,
        valueText: String,
        detailText: String?,
        symbolName: String
    ) {
        self.id = id
        self.title = title
        self.valueText = valueText
        self.detailText = detailText
        self.symbolName = symbolName
    }
}
