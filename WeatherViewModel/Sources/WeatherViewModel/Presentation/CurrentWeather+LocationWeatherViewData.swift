import WeatherModel

extension LocationWeatherViewData {

    init(
        weather: CurrentWeather,
        hourlyForecast: HourlyForecastViewData,
        formatter: any LocationWeatherFormatting
    ) {
        let condition = weather.conditions.first
        let feelsLikeTemperature = formatter.temperature(
            weather.temperature.feelsLike
        )

        locationName = weather.locationName
        countryCode = weather.sun.countryCode
        temperatureText = formatter.temperature(
            weather.temperature.temperature
        )
        feelsLikeText = "Feels like \(feelsLikeTemperature)"
        humidityText = formatter.percentage(
            weather.temperature.humidity
        )
        conditionText = condition.map {
            formatter.capitalizedFirstLetter($0.description)
        }
        conditionIconName = condition?.icon
        self.hourlyForecast = hourlyForecast
        tiles = []
    }
}
