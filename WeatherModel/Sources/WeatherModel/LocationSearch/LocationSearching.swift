/// Searches user-entered location text and returns coordinate-bearing matches.
public protocol LocationSearching: Sendable {

    /// Returns location candidates matching a natural-language query.
    func search(query: String) async throws -> [LocationSearchResult]
}
