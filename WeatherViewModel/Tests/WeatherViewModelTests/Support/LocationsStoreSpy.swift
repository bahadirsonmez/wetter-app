import WeatherModel

final class LocationsStoreSpy: LocationsStoring {

    var snapshot: SavedLocationsSnapshot
    var saveError: Error?
    private(set) var savedSnapshots: [SavedLocationsSnapshot] = []

    init(snapshot: SavedLocationsSnapshot = .empty) {
        self.snapshot = snapshot
    }

    func loadSnapshot() -> SavedLocationsSnapshot {
        snapshot
    }

    func saveSnapshot(_ snapshot: SavedLocationsSnapshot) throws {
        if let saveError {
            throw saveError
        }

        savedSnapshots.append(snapshot)
        self.snapshot = snapshot
    }
}
