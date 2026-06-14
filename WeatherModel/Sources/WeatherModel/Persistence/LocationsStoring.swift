public protocol LocationsStoring {

    func loadSnapshot() -> SavedLocationsSnapshot
    func saveSnapshot(_ snapshot: SavedLocationsSnapshot) throws
}
