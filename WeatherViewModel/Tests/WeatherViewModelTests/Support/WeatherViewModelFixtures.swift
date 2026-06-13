import Foundation
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

    static func forecastResponse(
        samples: [(timestamp: Int, temperature: Double, description: String)] = [
            (1_781_355_600, 24.4, "moderate rain")
        ],
        timezoneOffset: Int = 7_200
    ) -> ForecastResponse {
        let forecastObjects = samples.map {
            """
            {
              "dt": \($0.timestamp),
              "main": {
                "temp": \($0.temperature),
                "feels_like": \($0.temperature),
                "temp_min": \($0.temperature),
                "temp_max": \($0.temperature),
                "pressure": 1012,
                "humidity": 64
              },
              "weather": [
                {
                  "id": 500,
                  "main": "Rain",
                  "description": "\($0.description)",
                  "icon": "10d"
                }
              ],
              "clouds": { "all": 48 },
              "wind": { "speed": 4.2, "deg": 35 },
              "visibility": 10000,
              "pop": 0.35,
              "sys": { "pod": "d" },
              "dt_txt": "2026-06-13 13:00:00"
            }
            """
        }

        let json = """
        {
          "cnt": \(forecastObjects.count),
          "list": [\(forecastObjects.joined(separator: ","))],
          "city": {
            "id": 2950159,
            "name": "Berlin",
            "coord": { "lat": 52.52, "lon": 13.405 },
            "country": "DE",
            "timezone": \(timezoneOffset),
            "sunrise": 1781313240,
            "sunset": 1781368020
          }
        }
        """

        do {
            return try JSONDecoder().decode(
                ForecastResponse.self,
                from: Data(json.utf8)
            )
        } catch {
            preconditionFailure("Invalid forecast fixture: \(error)")
        }
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
