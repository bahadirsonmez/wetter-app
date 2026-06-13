import WeatherViewModel

enum LocationWeatherViewDataFixture {

    static func berlin(
        locationName: String = "Berlin",
        countryCode: String? = "DE",
        conditionText: String? = "Moderate rain"
    ) -> LocationWeatherViewData {
        LocationWeatherViewData(
            locationName: locationName,
            countryCode: countryCode,
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: conditionText,
            conditionIconName: "10d"
        )
    }
}
