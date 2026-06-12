import CoreLocation

@MainActor
protocol CurrentLocationProviding: AnyObject {

    var onLocationResult: (
        (Result<CLLocationCoordinate2D, CurrentLocationError>) -> Void
    )? { get set }

    func requestCurrentLocation()
}
