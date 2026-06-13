import CoreLocation
import XCTest
@testable import wetterApp

@MainActor
final class CurrentLocationProviderTests: XCTestCase {

    func testInitializationSetsLocationManagerDelegate() {
        let (provider, manager) = makeSUT()

        XCTAssertTrue(manager.delegate === provider)
    }

    func testRequestWhenAuthorizationIsNotDeterminedRequestsPermission() {
        let (provider, manager) = makeSUT(
            authorizationStatus: .notDetermined
        )

        provider.requestCurrentLocation()

        XCTAssertEqual(manager.requestAuthorizationCallCount, 1)
        XCTAssertEqual(manager.requestLocationCallCount, 0)
    }

    func testAuthorizationChangeWhenPermissionIsGrantedRequestsLocation() {
        let (provider, manager) = makeSUT(
            authorizationStatus: .notDetermined
        )
        provider.requestCurrentLocation()

        manager.authorizationStatus = .authorizedWhenInUse
        provider.handleAuthorizationChange()

        XCTAssertEqual(manager.requestLocationCallCount, 1)
    }

    func testRequestWhenAuthorizedRequestsLocation() {
        let (provider, manager) = makeSUT(
            authorizationStatus: .authorizedWhenInUse
        )

        provider.requestCurrentLocation()

        XCTAssertEqual(manager.requestLocationCallCount, 1)
    }

    func testRequestWhenServicesAreDisabledReturnsServicesDisabled() {
        let (provider, manager) = makeSUT(
            authorizationStatus: .authorizedWhenInUse,
            locationServicesEnabled: false
        )

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
        }

        XCTAssertEqual(result?.failure, .servicesDisabled)
        XCTAssertEqual(manager.requestLocationCallCount, 0)
    }

    func testDisabledServicesTakePrecedenceOverDeniedAuthorization() {
        let (provider, _) = makeSUT(
            authorizationStatus: .denied,
            locationServicesEnabled: false
        )

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
        }

        XCTAssertEqual(result?.failure, .servicesDisabled)
    }

    func testRequestWhenAuthorizationIsDeniedReturnsDenied() {
        let (provider, _) = makeSUT(authorizationStatus: .denied)

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
        }

        XCTAssertEqual(result?.failure, .authorizationDenied)
    }

    func testRequestWhenAuthorizationIsRestrictedReturnsRestricted() {
        let (provider, _) = makeSUT(authorizationStatus: .restricted)

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
        }

        XCTAssertEqual(result?.failure, .authorizationRestricted)
    }

    func testLocationUpdateReturnsLatestCoordinate() {
        let (provider, _) = makeSUT(
            authorizationStatus: .authorizedWhenInUse
        )
        var receivedResult: Result<
            CLLocationCoordinate2D,
            CurrentLocationError
        >?
        provider.onLocationResult = { receivedResult = $0 }
        provider.requestCurrentLocation()

        provider.handleLocationUpdate([
            CLLocation(latitude: 1, longitude: 1),
            CLLocation(latitude: 52.52, longitude: 13.405)
        ])

        XCTAssertEqual(receivedResult?.coordinate?.latitude, 52.52)
        XCTAssertEqual(receivedResult?.coordinate?.longitude, 13.405)
    }

    func testEmptyLocationUpdateReturnsLocationUnavailable() {
        let (provider, _) = makeSUT(
            authorizationStatus: .authorizedWhenInUse
        )

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
            provider.handleLocationUpdate([])
        }

        XCTAssertEqual(result?.failure, .locationUnavailable)
    }

    func testLocationFailureReturnsLocationUnavailable() {
        let (provider, _) = makeSUT(
            authorizationStatus: .authorizedWhenInUse
        )

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
            provider.handleLocationFailure(
                CLError(.locationUnknown)
            )
        }

        XCTAssertEqual(result?.failure, .locationUnavailable)
    }

    func testDeniedLocationFailureWhenAuthorizedReturnsServicesDisabled() {
        let (provider, _) = makeSUT(
            authorizationStatus: .authorizedWhenInUse
        )

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
            provider.handleLocationFailure(CLError(.denied))
        }

        XCTAssertEqual(result?.failure, .servicesDisabled)
    }

    func testDeniedLocationFailureWhenUnauthorizedReturnsUnavailable() {
        let (provider, manager) = makeSUT(
            authorizationStatus: .authorizedWhenInUse
        )

        let result = captureResult(from: provider) {
            provider.requestCurrentLocation()
            manager.authorizationStatus = .denied
            provider.handleLocationFailure(CLError(.denied))
        }

        XCTAssertEqual(result?.failure, .locationUnavailable)
    }

    func testDelegateResultWithoutPendingRequestIsIgnored() {
        let (provider, _) = makeSUT()
        var receivedResult: Result<
            CLLocationCoordinate2D,
            CurrentLocationError
        >?
        provider.onLocationResult = { receivedResult = $0 }

        provider.handleLocationUpdate([
            CLLocation(latitude: 52.52, longitude: 13.405)
        ])

        XCTAssertNil(receivedResult)
    }

    private func makeSUT(
        authorizationStatus: CLAuthorizationStatus = .notDetermined,
        locationServicesEnabled: Bool = true
    ) -> (CurrentLocationProvider, LocationManagerSpy) {
        let manager = LocationManagerSpy(
            authorizationStatus: authorizationStatus,
            locationServicesEnabled: locationServicesEnabled
        )
        return (
            CurrentLocationProvider(locationManager: manager),
            manager
        )
    }

    private func captureResult(
        from provider: CurrentLocationProvider,
        action: () -> Void
    ) -> Result<CLLocationCoordinate2D, CurrentLocationError>? {
        var result: Result<CLLocationCoordinate2D, CurrentLocationError>?
        provider.onLocationResult = { result = $0 }
        action()
        return result
    }
}

@MainActor
private final class LocationManagerSpy: LocationManaging {

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

private extension Result
where Success == CLLocationCoordinate2D,
      Failure == CurrentLocationError {

    var coordinate: CLLocationCoordinate2D? {
        try? get()
    }

    var failure: CurrentLocationError? {
        guard case let .failure(error) = self else {
            return nil
        }
        return error
    }
}
