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
    private var servicesCheckGeneration = 0

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

    func handleLocationFailure(_ error: Error) {
        let locationError = error as? CLError
        let isAuthorized = [
            CLAuthorizationStatus.authorizedAlways,
            .authorizedWhenInUse
        ].contains(locationManager.authorizationStatus)

        if locationError?.code == .denied, isAuthorized {
            complete(with: .failure(.servicesDisabled))
        } else {
            complete(with: .failure(.locationUnavailable))
        }
    }

    // MARK: - Private Methods

    private func continuePendingRequest() {
        guard isRequestPending else {
            return
        }

        switch locationManager.authorizationStatus {
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
        case .restricted:
            complete(with: .failure(.authorizationRestricted))
        case .authorizedAlways, .authorizedWhenInUse, .denied:
            checkLocationServicesAvailability()
        @unknown default:
            checkLocationServicesAvailability()
        }
    }

    private func checkLocationServicesAvailability() {
        servicesCheckGeneration += 1
        let generation = servicesCheckGeneration

        locationManager.checkLocationServicesEnabled { [weak self] isEnabled in
            guard
                let self,
                isRequestPending,
                generation == servicesCheckGeneration
            else {
                return
            }

            guard isEnabled else {
                complete(with: .failure(.servicesDisabled))
                return
            }

            continueAuthorizedRequest()
        }
    }

    private func continueAuthorizedRequest() {
        switch locationManager.authorizationStatus {
        case .authorizedAlways, .authorizedWhenInUse:
            locationManager.requestLocation()
        case .denied:
            complete(with: .failure(.authorizationDenied))
        case .restricted:
            complete(with: .failure(.authorizationRestricted))
        case .notDetermined:
            locationManager.requestWhenInUseAuthorization()
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
        servicesCheckGeneration += 1
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
        handleLocationFailure(error)
    }
}
