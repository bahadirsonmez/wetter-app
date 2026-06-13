import WeatherViewModel

enum LocationWeatherViewDataFixture {

    static func berlin(
        locationName: String = "Berlin",
        countryCode: String? = "DE",
        conditionText: String? = "Moderate rain",
        hourlyForecast: HourlyForecastViewData =
            LocationWeatherViewDataFixture.berlinForecast
    ) -> LocationWeatherViewData {
        LocationWeatherViewData(
            locationName: locationName,
            countryCode: countryCode,
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: conditionText,
            conditionIconName: "10d",
            hourlyForecast: hourlyForecast
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
}
