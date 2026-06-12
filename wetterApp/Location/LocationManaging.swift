import CoreLocation

@MainActor
protocol LocationManaging: AnyObject {

    var delegate: CLLocationManagerDelegate? { get set }
    var authorizationStatus: CLAuthorizationStatus { get }
    var locationServicesEnabled: Bool { get }

    func requestWhenInUseAuthorization()
    func requestLocation()
}

extension CLLocationManager: LocationManaging {

    var locationServicesEnabled: Bool {
        CLLocationManager.locationServicesEnabled()
    }
}
