public struct HourlyForecastDayViewData: Equatable, Sendable {

    public let id: Int
    public let title: String
    public let items: [HourlyForecastItemViewData]

    public init(
        id: Int,
        title: String,
        items: [HourlyForecastItemViewData]
    ) {
        self.id = id
        self.title = title
        self.items = items
    }
}
