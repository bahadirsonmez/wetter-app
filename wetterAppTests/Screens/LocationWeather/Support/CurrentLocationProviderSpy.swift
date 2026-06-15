import CoreLocation
@testable import wetterApp

@MainActor
final class CurrentLocationProviderSpy: CurrentLocationProviding {

    var onLocationResult: (
        (Result<CLLocationCoordinate2D, CurrentLocationError>) -> Void
    )?

    private(set) var requestCallCount = 0

    func requestCurrentLocation() {
        requestCallCount += 1
    }

    func send(
        _ result: Result<CLLocationCoordinate2D, CurrentLocationError>
    ) {
        onLocationResult?(result)
    }
}
