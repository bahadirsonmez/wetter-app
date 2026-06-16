import CoreLocation
@testable import wetterApp

@MainActor
final class LocationManagerSpy: LocationManaging {

    weak var delegate: CLLocationManagerDelegate?
    var authorizationStatus: CLAuthorizationStatus

    private(set) var requestAuthorizationCallCount = 0
    private(set) var requestLocationCallCount = 0

    init(authorizationStatus: CLAuthorizationStatus) {
        self.authorizationStatus = authorizationStatus
    }

    func requestWhenInUseAuthorization() {
        requestAuthorizationCallCount += 1
    }

    func requestLocation() {
        requestLocationCallCount += 1
    }
}
