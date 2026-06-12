import WeatherModel

extension LocationWeatherViewData {

    init(weather: CurrentWeather) {
        self.init(
            weather: weather,
            formatter: LocationWeatherFormatter()
        )
    }

    init(
        weather: CurrentWeather,
        formatter: any LocationWeatherFormatting
    ) {
        let condition = weather.conditions.first
        let conditionDescription = condition?.description
        let feelsLikeTemperature = formatter.temperature(
            weather.temperature.feelsLike
        )

        locationName = weather.locationName.isEmpty
            ? "Unknown location"
            : weather.locationName
        countryCode = weather.sun.countryCode
        temperatureText = formatter.temperature(
            weather.temperature.temperature
        )
        feelsLikeText = "Feels like \(feelsLikeTemperature)"
        humidityText = formatter.percentage(
            weather.temperature.humidity
        )
        conditionText = conditionDescription.map {
            $0.isEmpty
                ? "Unknown"
                : formatter.capitalizedFirstLetter($0)
        } ?? "Unknown"
        conditionIconName = condition?.icon
    }
}
