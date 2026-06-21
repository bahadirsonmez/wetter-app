import Foundation
import WeatherModel

final class UserDefaultsLocationsStore: LocationsStoring {

    // MARK: - Constants

    private enum Constants {
        static let snapshotKey =
            "com.bahadirovski.wetterApp.savedLocations.v1"
    }

    // MARK: - Properties

    private let userDefaults: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    // MARK: - Initialization

    init(
        userDefaults: UserDefaults = .standard,
        encoder: JSONEncoder = JSONEncoder(),
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.userDefaults = userDefaults
        self.encoder = encoder
        self.decoder = decoder
    }

    // MARK: - LocationsStoring

    func loadSnapshot() -> SavedLocationsSnapshot {
        guard
            let data = userDefaults.data(forKey: Constants.snapshotKey),
            let snapshot = try? decoder.decode(
                SavedLocationsSnapshot.self,
                from: data
            )
        else {
            return .empty
        }

        return snapshot
    }

    func saveSnapshot(_ snapshot: SavedLocationsSnapshot) throws {
        do {
            let data = try encoder.encode(snapshot)
            userDefaults.set(data, forKey: Constants.snapshotKey)
        } catch {
            throw LocationsStoreError.encodingFailed
        }
    }
}
