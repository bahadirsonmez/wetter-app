/// Persists and loads the saved-location snapshot used by the app.
public protocol LocationsStoring {

    /// Returns the latest saved-location snapshot, or an empty snapshot when none exists.
    func loadSnapshot() -> SavedLocationsSnapshot

    /// Replaces the stored saved-location snapshot.
    func saveSnapshot(_ snapshot: SavedLocationsSnapshot) throws
}
