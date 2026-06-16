import CoreLocation

@MainActor
protocol LocationManaging: AnyObject {

    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }

    func requestWhenInUseAuthorization()
    func requestLocation()
}

extension CLLocationManager: LocationManaging {}
