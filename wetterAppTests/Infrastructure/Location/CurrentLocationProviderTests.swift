import CoreLocation
import WeatherModel
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
            Coordinates,
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
            Coordinates,
            CurrentLocationError
        >?
        provider.onLocationResult = { receivedResult = $0 }

        provider.handleLocationUpdate([
            CLLocation(latitude: 52.52, longitude: 13.405)
        ])

        XCTAssertNil(receivedResult)
    }

    private func makeSUT(
        authorizationStatus: CLAuthorizationStatus = .notDetermined
    ) -> (CurrentLocationProvider, LocationManagerSpy) {
        let manager = LocationManagerSpy(
            authorizationStatus: authorizationStatus
        )
        return (
            CurrentLocationProvider(locationManager: manager),
            manager
        )
    }

    private func captureResult(
        from provider: CurrentLocationProvider,
        action: () -> Void
    ) -> Result<Coordinates, CurrentLocationError>? {
        var result: Result<Coordinates, CurrentLocationError>?
        provider.onLocationResult = { result = $0 }
        action()
        return result
    }
}

private extension Result
where Success == Coordinates,
      Failure == CurrentLocationError {

    var coordinate: Coordinates? {
        try? get()
    }

    var failure: CurrentLocationError? {
        guard case let .failure(error) = self else {
            return nil
        }
        return error
    }
}
