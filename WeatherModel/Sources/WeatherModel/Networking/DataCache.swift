import Foundation

actor DataCache {
    struct Entry {
        let data: Data
        let timestamp: Date
    }

    private var entries: [String: Entry] = [:]
    private let dateProvider: () -> Date

    init(dateProvider: @escaping () -> Date = Date.init) {
        self.dateProvider = dateProvider
    }

    func set(_ data: Data, for key: String) {
        entries[key] = Entry(data: data, timestamp: dateProvider())
    }

    func get(for key: String, maxAge: TimeInterval) -> Data? {
        guard let entry = entries[key] else { return nil }
        if dateProvider().timeIntervalSince(entry.timestamp) > maxAge {
            entries.removeValue(forKey: key)
            return nil
        }
        return entry.data
    }
}
