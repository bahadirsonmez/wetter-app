import CoreLocation
@testable import wetterApp

@MainActor
final class LocationManagerSpy: LocationManaging {

    weak var delegate: CLLocationManagerDelegate?
    var authorizationStatus: CLAuthorizationStatus
    var locationServicesEnabled: Bool

    private(set) var requestAuthorizationCallCount = 0
    private(set) var requestLocationCallCount = 0
    private(set) var servicesCheckCallCount = 0

    init(
        authorizationStatus: CLAuthorizationStatus,
        locationServicesEnabled: Bool
    ) {
        self.authorizationStatus = authorizationStatus
        self.locationServicesEnabled = locationServicesEnabled
    }

    func requestWhenInUseAuthorization() {
        requestAuthorizationCallCount += 1
    }

    func requestLocation() {
        requestLocationCallCount += 1
    }

    func checkLocationServicesEnabled(
        completion: @escaping @MainActor @Sendable (Bool) -> Void
    ) {
        servicesCheckCallCount += 1
        completion(locationServicesEnabled)
    }
}
