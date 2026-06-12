import CoreLocation

@MainActor
final class CurrentLocationProvider: NSObject, CurrentLocationProviding {

    // MARK: - Public Properties

    var onLocationResult: (
        (Result<CLLocationCoordinate2D, CurrentLocationError>) -> Void
    )?

    // MARK: - Private Properties

    private let locationManager: any LocationManaging
    private var isRequestPending = false

    // MARK: - Initialization

    init(locationManager: any LocationManaging = CLLocationManager()) {
        self.locationManager = locationManager
        super.init()
        self.locationManager.delegate = self
    }

    // MARK: - Public Methods

    func requestCurrentLocation() {
        isRequestPending = true
        continuePendingRequest()
    }

    // MARK: - Delegate Event Handling

    func handleAuthorizationChange() {
        continuePendingRequest()
    }

    func handleLocationUpdate(_ locations: [CLLocation]) {
        guard let coordinate = locations.last?.coordinate else {
            complete(with: .failure(.locationUnavailable))
            return
        }

        complete(with: .success(coordinate))
    }

    func handleLocationFailure() {
        complete(with: .failure(.locationUnavailable))
    }

    // MARK: - Private Methods

    private func continuePendingRequest() {
        guard isRequestPending else {
            return
        }

        guard locationManager.locationServicesEnabled else {
            complete(with: .failure(.servicesDisabled))
            return
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied:
            complete(with: .failure(.authorizationDenied))
        case .restricted:
            complete(with: .failure(.authorizationRestricted))
        @unknown default:
            complete(with: .failure(.locationUnavailable))
        }
    }

    private func complete(
        with result: Result<CLLocationCoordinate2D, CurrentLocationError>
    ) {
        guard isRequestPending else {
            return
        }

        isRequestPending = false
        onLocationResult?(result)
    }
}

// MARK: - CLLocationManagerDelegate

extension CurrentLocationProvider: CLLocationManagerDelegate {

    func locationManagerDidChangeAuthorization(
        _ manager: CLLocationManager
    ) {
        handleAuthorizationChange()
    }

    func locationManager(
        _ manager: CLLocationManager,
        didUpdateLocations locations: [CLLocation]
    ) {
        handleLocationUpdate(locations)
    }

    func locationManager(
        _ manager: CLLocationManager,
        didFailWithError error: Error
    ) {
        handleLocationFailure()
    }
}
