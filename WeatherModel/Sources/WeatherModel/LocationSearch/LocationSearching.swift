public protocol LocationSearching: Sendable {

    func search(query: String) async throws -> [LocationSearchResult]
}
