public struct CloudDetails: Codable, Equatable, Sendable {

    public let coverage: Int

    enum CodingKeys: String, CodingKey {
        case coverage = "all"
    }
}
