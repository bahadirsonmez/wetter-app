import Foundation
import WeatherModel

@MainActor
public final class LocationWeatherViewModel: LocationWeatherViewModeling {

    // MARK: - Public Properties

    public let source: LocationWeatherSource
    public private(set) var state: LocationWeatherViewState = .idle
    public var onStateChange: ((LocationWeatherViewState) -> Void)?

    // MARK: - Private Properties

    private let locationProvider: (any CurrentLocationProviding)?
    private let weatherService: any WeatherFetching
    private let formatter: any LocationWeatherFormatting
    private let forecastMapper: ForecastViewDataMapper
    private var currentTask: Task<Void, Never>?
    private var lastCoordinates: WeatherCoordinates?

    // MARK: - Initialization

    public init(
        source: LocationWeatherSource = .current,
        weatherService: any WeatherFetching,
        locationProvider: (any CurrentLocationProviding)? = nil,
        formatter: any LocationWeatherFormatting = LocationWeatherFormatter(),
        forecastFormatter: any ForecastFormatting = ForecastFormatter()
    ) {
        self.source = source
        self.locationProvider = locationProvider
        self.weatherService = weatherService
        self.formatter = formatter
        forecastMapper = ForecastViewDataMapper(formatter: forecastFormatter)
        bindLocationProvider()
    }

    deinit {
        currentTask?.cancel()
    }

    // MARK: - Public Methods

    /// Starts loading weather for the configured current or saved location source.
    public func loadInitialWeather() {
        switch source {
        case .current:
            requestCurrentLocation()
        case let .saved(route):
            loadWeather(
                latitude: route.latitude,
                longitude: route.longitude
            )
        }
    }

    /// Loads the weather and forecast for the specified coordinates.
    public func loadWeather(latitude: Double, longitude: Double) {
        lastCoordinates = WeatherCoordinates(
            latitude: latitude,
            longitude: longitude
        )
        fetchWeather(latitude: latitude, longitude: longitude)
    }

    /// Refreshes the weather and forecast using the last known coordinates, bypassing local cache.
    public func refresh() {
        guard let lastCoordinates else {
            return
        }

        fetchWeather(
            latitude: lastCoordinates.latitude,
            longitude: lastCoordinates.longitude,
            forceRefresh: true
        )
    }

    /// Requests current location again after scene activation for current-location screens.
    public func requestCurrentLocationAfterActivation() {
        guard source == .current else {
            return
        }

        requestCurrentLocation()
    }

    // MARK: - Private Methods

    private func bindLocationProvider() {
        locationProvider?.onLocationResult = { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case let .success(coordinates):
                loadWeather(
                    latitude: coordinates.latitude,
                    longitude: coordinates.longitude
                )
            case let .failure(error):
                updateState(.failed(LocationWeatherViewError(error: error)))
            }
        }
    }

    private func requestCurrentLocation() {
        updateState(.loading)

        guard let locationProvider else {
            updateState(.failed(.unavailable))
            return
        }

        locationProvider.requestCurrentLocation()
    }

    // Capture only the service during the request so the task does not retain
    // the ViewModel and prevent deinit from cancelling the active task.
    private func fetchWeather(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool = false
    ) {
        currentTask?.cancel()
        updateState(.loading)

        let service = weatherService
        currentTask = Task { [weak self] in
            do {
                async let weatherRequest = service.fetchCurrentWeather(
                    latitude: latitude,
                    longitude: longitude,
                    forceRefresh: forceRefresh
                )
                async let forecastRequest = service.fetchForecast(
                    latitude: latitude,
                    longitude: longitude,
                    forceRefresh: forceRefresh
                )
                let (weather, forecast) = try await (
                    weatherRequest,
                    forecastRequest
                )

                // A newer request may have started while these async lets
                // were in flight; stale results must not overwrite state.
                guard !Task.isCancelled, let self else {
                    return
                }

                let hourlyForecast = forecastMapper.map(forecast)
                updateState(
                    .loaded(
                        LocationWeatherViewData(
                            weather: weather,
                            hourlyForecast: hourlyForecast,
                            formatter: formatter
                        )
                    )
                )
            } catch is CancellationError {
                return
            } catch {
                // Cancellation is handled above. Other failures should only
                // publish if this task still owns the latest request.
                guard !Task.isCancelled, let self else {
                    return
                }

                updateState(
                    .failed(LocationWeatherViewError(error: error))
                )
            }
        }
    }

    private func updateState(_ newState: LocationWeatherViewState) {
        state = newState
        onStateChange?(newState)
    }

}
