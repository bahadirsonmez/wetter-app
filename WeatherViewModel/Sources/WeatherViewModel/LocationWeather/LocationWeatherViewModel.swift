import Foundation
import WeatherModel

@MainActor
public final class LocationWeatherViewModel: LocationWeatherViewModeling {

    // MARK: - Public Properties

    public private(set) var state: LocationWeatherViewState = .idle
    public var onStateChange: ((LocationWeatherViewState) -> Void)?

    // MARK: - Private Properties

    private let weatherService: any WeatherFetching
    private let formatter: any LocationWeatherFormatting
    private let forecastMapper: ForecastViewDataMapper
    private var currentTask: Task<Void, Never>?
    private var lastCoordinates: WeatherCoordinates?

    // MARK: - Initialization

    public init(
        weatherService: any WeatherFetching,
        formatter: any LocationWeatherFormatting = LocationWeatherFormatter(),
        forecastFormatter: any ForecastFormatting = ForecastFormatter()
    ) {
        self.weatherService = weatherService
        self.formatter = formatter
        forecastMapper = ForecastViewDataMapper(formatter: forecastFormatter)
    }

    deinit {
        currentTask?.cancel()
    }

    // MARK: - Public Methods

    public func loadWeather(latitude: Double, longitude: Double) {
        lastCoordinates = WeatherCoordinates(
            latitude: latitude,
            longitude: longitude
        )
        fetchWeather(latitude: latitude, longitude: longitude)
    }

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

    // MARK: - Private Methods

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
