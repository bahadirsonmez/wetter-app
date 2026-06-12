import Foundation
import WeatherModel

func makeCurrentWeather(
    locationName: String = "Berlin",
    countryCode: String? = "DE",
    temperature: Double = 24.4,
    feelsLikeTemperature: Double = 24.6,
    humidity: Int = 64,
    includesCondition: Bool = true,
    conditionDescription: String = "moderate rain",
    conditionIcon: String = "10d"
) throws -> CurrentWeather {
    let countryEntry: String
    if let countryCode {
        countryEntry = #""country": "\#(countryCode)","#
    } else {
        countryEntry = ""
    }
    let conditions = includesCondition
        ? """
          [
            {
              "id": 501,
              "main": "Rain",
              "description": "\(conditionDescription)",
              "icon": "\(conditionIcon)"
            }
          ]
          """
        : "[]"

    let json = """
    {
      "coord": { "lon": 13.405, "lat": 52.52 },
      "weather": \(conditions),
      "main": {
        "temp": \(temperature),
        "feels_like": \(feelsLikeTemperature),
        "temp_min": 23.0,
        "temp_max": 25.0,
        "pressure": 1015,
        "humidity": \(humidity)
      },
      "visibility": 10000,
      "wind": { "speed": 2.5, "deg": 180 },
      "clouds": { "all": 75 },
      "dt": 1781179200,
      "sys": {
        \(countryEntry)
        "sunrise": 1781140440,
        "sunset": 1781195220
      },
      "timezone": 7200,
      "id": 2950159,
      "name": "\(locationName)"
    }
    """

    return try JSONDecoder().decode(
        CurrentWeather.self,
        from: Data(json.utf8)
    )
}
