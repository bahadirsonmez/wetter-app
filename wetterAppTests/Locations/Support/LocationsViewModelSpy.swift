import Foundation
import WeatherViewModel

@MainActor
final class LocationsViewModelSpy: LocationsViewModeling {

    var items: [LocationsListItemViewData] = []
    var onItemsChange: (([LocationsListItemViewData]) -> Void)?
    var onLocationSelected: ((LocationsListItemIdentifier) -> Void)?
    var onError: ((LocationsViewError) -> Void)?

    private(set) var loadLocationsCallCount = 0
    private(set) var selectedIdentifiers: [LocationsListItemIdentifier] = []
    private(set) var deletedLocationIDs: [UUID] = []
    private(set) var receivedMoves: [(from: Int, to: Int)] = []

    func loadLocations() {
        loadLocationsCallCount += 1
        onItemsChange?(items)
    }

    func selectLocation(id: LocationsListItemIdentifier) {
        selectedIdentifiers.append(id)
        onLocationSelected?(id)
    }

    func deleteLocation(id: UUID) {
        deletedLocationIDs.append(id)
    }

    func moveLocation(fromSavedIndex: Int, toSavedIndex: Int) {
        receivedMoves.append((fromSavedIndex, toSavedIndex))
    }

    func send(_ items: [LocationsListItemViewData]) {
        self.items = items
        onItemsChange?(items)
    }
}
