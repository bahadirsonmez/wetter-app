import Foundation
import WeatherModel

@MainActor
public final class LocationsViewModel: LocationsViewModeling {

    // MARK: - Public Properties

    public private(set) var items: [LocationsListItemViewData] = []
    public var onItemsChange: (([LocationsListItemViewData]) -> Void)?
    public var onLocationSelected: ((LocationsListItemIdentifier) -> Void)?
    public var onLocationDeleted: ((UUID) -> Void)?
    public var onError: ((LocationsViewError) -> Void)?

    // MARK: - Private Properties

    private let store: any LocationsStoring
    private var snapshot: SavedLocationsSnapshot = .empty

    // MARK: - Initialization

    public init(store: any LocationsStoring) {
        self.store = store
    }

    // MARK: - Public Methods

    public func loadLocations() {
        snapshot = store.loadSnapshot()
        publishItems()
    }

    public func selectLocation(id: LocationsListItemIdentifier) {
        let selectedLocationID: UUID?

        switch id {
        case .current:
            selectedLocationID = nil
        case let .saved(id):
            guard snapshot.locations.contains(where: { $0.id == id }) else {
                return
            }
            selectedLocationID = id
        }

        let updatedSnapshot = SavedLocationsSnapshot(
            locations: snapshot.locations,
            lastViewedLocationID: selectedLocationID
        )

        guard persist(updatedSnapshot) else {
            return
        }

        onLocationSelected?(id)
    }

    public func deleteLocation(id: UUID) {
        guard snapshot.locations.contains(where: { $0.id == id }) else {
            return
        }

        let updatedSnapshot = SavedLocationsSnapshot(
            locations: snapshot.locations.filter { $0.id != id },
            lastViewedLocationID: snapshot.lastViewedLocationID == id
                ? nil
                : snapshot.lastViewedLocationID
        )

        guard persist(updatedSnapshot) else {
            return
        }

        publishItems()
        onLocationDeleted?(id)
    }

    public func moveLocation(
        fromSavedIndex: Int,
        toSavedIndex: Int
    ) {
        guard
            snapshot.locations.indices.contains(fromSavedIndex),
            toSavedIndex >= .zero,
            toSavedIndex < snapshot.locations.count,
            fromSavedIndex != toSavedIndex
        else {
            return
        }

        var locations = snapshot.locations
        let location = locations.remove(at: fromSavedIndex)
        locations.insert(location, at: toSavedIndex)
        let updatedSnapshot = SavedLocationsSnapshot(
            locations: locations,
            lastViewedLocationID: snapshot.lastViewedLocationID
        )

        guard persist(updatedSnapshot) else {
            return
        }

        publishItems()
    }

    // MARK: - Private Methods

    private func persist(_ updatedSnapshot: SavedLocationsSnapshot) -> Bool {
        do {
            try store.saveSnapshot(updatedSnapshot)
            snapshot = updatedSnapshot
            return true
        } catch {
            onError?(.persistenceFailed)
            return false
        }
    }

    private func publishItems() {
        items = [
            LocationsListItemViewData(
                identifier: .current,
                title: "Current Location",
                subtitle: nil,
                isDeletable: false,
                isMovable: false
            )
        ] + snapshot.locations.map(makeItem)

        onItemsChange?(items)
    }

    private func makeItem(
        for location: SavedLocation
    ) -> LocationsListItemViewData {
        let subtitleParts: [String] = [
            location.state,
            location.countryCode
        ]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else {
                    return nil
                }
                return value
            }

        return LocationsListItemViewData(
            identifier: .saved(location.id),
            title: location.name,
            subtitle: subtitleParts.isEmpty
                ? nil
                : subtitleParts.joined(separator: ", "),
            isDeletable: true,
            isMovable: true
        )
    }
}
