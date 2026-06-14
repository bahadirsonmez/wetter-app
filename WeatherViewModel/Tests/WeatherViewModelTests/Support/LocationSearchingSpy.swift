import Foundation
import WeatherModel

final class LocationSearchingSpy: LocationSearching, @unchecked Sendable {

    var handler: @Sendable (String) async throws -> [LocationSearchResult]

    private let lock = NSLock()
    private var queriesStorage: [String] = []

    var queries: [String] {
        lock.withLock { queriesStorage }
    }

    init(
        handler: @escaping @Sendable (String) async throws -> [LocationSearchResult]
    ) {
        self.handler = handler
    }

    convenience init(
        result: Result<[LocationSearchResult], Error> = .success([])
    ) {
        self.init { _ in
            try result.get()
        }
    }

    func search(query: String) async throws -> [LocationSearchResult] {
        lock.withLock {
            queriesStorage.append(query)
        }
        return try await handler(query)
    }
}

private extension NSLock {

    func withLock<T>(_ action: () -> T) -> T {
        lock()
        defer { unlock() }
        return action()
    }
}
