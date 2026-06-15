import Foundation

@MainActor
public protocol LocationsViewModeling: AnyObject {

    var items: [LocationsListItemViewData] { get }
    var onItemsChange: (([LocationsListItemViewData]) -> Void)? { get set }
    var onLocationSelected: ((LocationsListItemIdentifier) -> Void)? { get set }
    var onLocationDeleted: ((UUID) -> Void)? { get set }
    var onError: ((LocationsViewError) -> Void)? { get set }

    func loadLocations()
    func selectLocation(id: LocationsListItemIdentifier)
    func deleteLocation(id: UUID)
    func moveLocation(fromSavedIndex: Int, toSavedIndex: Int)
}
