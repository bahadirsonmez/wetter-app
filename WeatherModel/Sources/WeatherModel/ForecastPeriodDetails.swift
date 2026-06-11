public struct ForecastPeriodDetails: Codable, Equatable, Sendable {

    public let partOfDay: String

    enum CodingKeys: String, CodingKey {
        case partOfDay = "pod"
    }
}
