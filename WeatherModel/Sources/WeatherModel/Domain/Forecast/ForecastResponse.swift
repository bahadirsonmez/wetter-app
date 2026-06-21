/// Represents a paginated or complete hourly forecast response for a location.
public struct ForecastResponse: Codable, Equatable, Sendable {

    public let count: Int
    public let forecasts: [HourlyForecast]
    public let location: ForecastLocation

    enum CodingKeys: String, CodingKey {
        case count = "cnt"
        case forecasts = "list"
        case location = "city"
    }
}
