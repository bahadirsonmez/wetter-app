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
    private var coordinates: StoredCoordinates?
    private var loadTask: Task<Void, Never>?

    // MARK: - Initialization

    public init(
        weatherService: any WeatherFetching,
        formatter: any LocationWeatherFormatting = LocationWeatherFormatter()
    ) {
        self.weatherService = weatherService
        self.formatter = formatter
    }

    // MARK: - Public Methods

    public func loadWeather(latitude: Double, longitude: Double) {
        coordinates = StoredCoordinates(
            latitude: latitude,
            longitude: longitude
        )
        fetchWeather(latitude: latitude, longitude: longitude)
    }

    public func refresh() {
        guard let coordinates else {
            return
        }

        fetchWeather(
            latitude: coordinates.latitude,
            longitude: coordinates.longitude
        )
    }

    // MARK: - Private Methods

    private func fetchWeather(latitude: Double, longitude: Double) {
        loadTask?.cancel()
        updateState(.loading)

        loadTask = Task { [weak self] in
            guard let self else {
                return
            }

            do {
                let weather = try await weatherService.fetchCurrentWeather(
                    latitude: latitude,
                    longitude: longitude
                )

                guard !Task.isCancelled else {
                    return
                }

                updateState(.loaded(makeViewData(from: weather)))
            } catch is CancellationError {
                return
            } catch let error as NetworkError {
                guard !Task.isCancelled else {
                    return
                }

                updateState(.failed(makeViewError(from: error)))
            } catch {
                guard !Task.isCancelled else {
                    return
                }

                updateState(.failed(.unknown))
            }
        }
    }

    private func updateState(_ state: LocationWeatherViewState) {
        self.state = state
        onStateChange?(state)
    }

    // MARK: - Mapping Helpers

    private func makeViewData(
        from weather: CurrentWeather
    ) -> LocationWeatherViewData {
        let condition = weather.conditions.first
        let temperature = formatter.temperature(
            weather.temperature.temperature
        )
        let feelsLikeTemperature = formatter.temperature(
            weather.temperature.feelsLike
        )

        return LocationWeatherViewData(
            locationName: weather.locationName,
            countryCode: weather.sun.countryCode,
            temperatureText: temperature,
            feelsLikeText: "Feels like \(feelsLikeTemperature)",
            humidityText: formatter.percentage(
                weather.temperature.humidity
            ),
            conditionText: condition.map {
                formatter.capitalizedFirstLetter($0.description)
            },
            conditionIconName: condition?.icon
        )
    }

    private func makeViewError(
        from error: NetworkError
    ) -> LocationWeatherViewError {
        switch error {
        case .unauthorized:
            .unauthorized
        case .invalidResponse:
            .unavailable
        case .decodingFailed:
            .invalidData
        case .invalidURL:
            .unknown
        }
    }
}

// MARK: - Private Types

private struct StoredCoordinates {
    let latitude: Double
    let longitude: Double
}
