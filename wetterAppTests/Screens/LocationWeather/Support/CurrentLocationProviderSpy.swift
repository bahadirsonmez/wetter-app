import WeatherModel
@testable import wetterApp

@MainActor
final class CurrentLocationProviderSpy: CurrentLocationProviding {

    var onLocationResult: (
        (Result<Coordinates, CurrentLocationError>) -> Void
    )?

    private(set) var requestCallCount = 0

    func requestCurrentLocation() {
        requestCallCount += 1
    }

    func send(
        _ result: Result<Coordinates, CurrentLocationError>
    ) {
        onLocationResult?(result)
    }
}
