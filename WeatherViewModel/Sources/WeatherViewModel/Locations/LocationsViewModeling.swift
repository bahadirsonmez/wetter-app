import Foundation

/// Manages the current-location row and saved-location list for the locations screen.
@MainActor
public protocol LocationsViewModeling: AnyObject {

    var items: [LocationsListItemViewData] { get }
    var onItemsChange: (([LocationsListItemViewData]) -> Void)? { get set }
    var onLocationSelected: ((LocationsListItemIdentifier) -> Void)? { get set }
    var onLocationDeleted: ((UUID) -> Void)? { get set }
    var onError: ((LocationsViewError) -> Void)? { get set }

    /// Loads the current snapshot and publishes list items.
    func loadLocations()

    /// Selects either the current location row or a saved location row.
    func selectLocation(id: LocationsListItemIdentifier)

    /// Deletes a saved location by identifier.
    func deleteLocation(id: UUID)

    /// Reorders saved locations using indexes that exclude the current-location row.
    func moveLocation(fromSavedIndex: Int, toSavedIndex: Int)
}
