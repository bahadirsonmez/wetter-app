/// Provides the user's current location as platform-independent coordinates.
@MainActor
public protocol CurrentLocationProviding: AnyObject {

    var onLocationResult: (
        (Result<Coordinates, CurrentLocationError>) -> Void
    )? { get set }

    func requestCurrentLocation()
}
