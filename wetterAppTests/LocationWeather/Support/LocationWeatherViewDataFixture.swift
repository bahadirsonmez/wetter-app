import WeatherViewModel

enum LocationWeatherViewDataFixture {

    static func berlin(
        locationName: String = "Berlin",
        countryCode: String? = "DE",
        conditionText: String? = "Moderate rain",
        hourlyForecast: HourlyForecastViewData =
            LocationWeatherViewDataFixture.berlinForecast,
        tiles: [WeatherTileViewData] = []
    ) -> LocationWeatherViewData {
        LocationWeatherViewData(
            locationName: locationName,
            countryCode: countryCode,
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: conditionText,
            conditionIconName: "10d",
            hourlyForecast: hourlyForecast,
            tiles: tiles
        )
    }

    static let berlinForecast = HourlyForecastViewData(
        days: [
            HourlyForecastDayViewData(
                id: 1_781_304_000,
                title: "Saturday, Jun 13",
                items: [
                    HourlyForecastItemViewData(
                        id: 1_781_312_400,
                        timeText: "15:00",
                        temperatureText: "24°C",
                        conditionText: "Moderate rain",
                        temperatureValue: 24
                    )
                ]
            )
        ],
        minimumTemperature: 24,
        maximumTemperature: 24
    )

    static let emptyForecast = HourlyForecastViewData(
        days: [],
        minimumTemperature: .zero,
        maximumTemperature: .zero
    )

    static func tiles(
        minimumTemperature: String = "23°C"
    ) -> [WeatherTileViewData] {
        [
            WeatherTileViewData(
                id: .minimumTemperature,
                title: "Minimum",
                valueText: minimumTemperature,
                detailText: nil,
                symbolName: "thermometer"
            ),
            WeatherTileViewData(
                id: .maximumTemperature,
                title: "Maximum",
                valueText: "25°C",
                detailText: nil,
                symbolName: "thermometer"
            )
        ]
    }
}
