public struct PrecipitationDetails: Codable, Equatable, Sendable {

    public let lastHour: Double?
    public let lastThreeHours: Double?

    enum CodingKeys: String, CodingKey {
        case lastHour = "1h"
        case lastThreeHours = "3h"
    }
}
