import CoreLocation

protocol CurrentLocationProviding: AnyObject {}

final class CurrentLocationProvider: CurrentLocationProviding {

    private let locationManager: CLLocationManager

    init(locationManager: CLLocationManager = CLLocationManager()) {
        self.locationManager = locationManager
    }
}
