import CoreLocation

@MainActor
protocol LocationManaging: AnyObject {

    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }

    func requestWhenInUseAuthorization()
    func requestLocation()
    func checkLocationServicesEnabled(
        completion: @escaping @MainActor @Sendable (Bool) -> Void
    )
}

extension CLLocationManager: LocationManaging {

    func checkLocationServicesEnabled(
        completion: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        Task.detached(priority: .userInitiated) {
            let isEnabled = CLLocationManager.locationServicesEnabled()
            await completion(isEnabled)
        }
    }
}
