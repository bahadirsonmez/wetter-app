@testable import WeatherModel

enum WeatherViewModelFixtures {

    static let berlinWeather = makeWeather()

    static let weatherWithoutCondition = makeWeather(
        conditions: []
    )

    static let weatherWithoutCountryCode = makeWeather(
        countryCode: nil
    )

    static let negativeTemperatureWeather = makeWeather(
        temperature: -2.6,
        feelsLike: -2.6
    )

    static let weatherWithEmptyLocationName = makeWeather(
        locationName: ""
    )

    static let weatherWithEmptyConditionDescription = makeWeather(
        conditions: [
            WeatherCondition(
                id: 501,
                group: "Rain",
                description: "",
                icon: "10d"
            )
        ]
    )

    static func weather(locationName: String) -> CurrentWeather {
        makeWeather(locationName: locationName)
    }

    private static func makeWeather(
        locationName: String = "Berlin",
        countryCode: String? = "DE",
        temperature: Double = 24.4,
        feelsLike: Double = 24.6,
        conditions: [WeatherCondition] = [
            WeatherCondition(
                id: 501,
                group: "Rain",
                description: "moderate rain",
                icon: "10d"
            )
        ]
    ) -> CurrentWeather {
        CurrentWeather(
            coordinates: Coordinates(
                latitude: 52.52,
                longitude: 13.405
            ),
            conditions: conditions,
            temperature: TemperatureDetails(
                temperature: temperature,
                feelsLike: feelsLike,
                minimumTemperature: 23,
                maximumTemperature: 25,
                pressure: 1015,
                humidity: 64,
                seaLevelPressure: nil,
                groundLevelPressure: nil
            ),
            visibility: 10_000,
            wind: WindDetails(
                speed: 2.5,
                direction: 180,
                gust: nil
            ),
            clouds: CloudDetails(coverage: 75),
            rain: nil,
            snow: nil,
            timestamp: 1_781_179_200,
            sun: SunDetails(
                countryCode: countryCode,
                sunriseTime: 1_781_140_440,
                sunsetTime: 1_781_195_220
            ),
            timezoneOffset: 7_200,
            locationID: 2_950_159,
            locationName: locationName
        )
    }
}
