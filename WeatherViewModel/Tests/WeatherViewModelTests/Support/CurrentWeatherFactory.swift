import Foundation
import WeatherModel

func makeCurrentWeather(
    locationName: String = "Berlin",
    countryCode: String? = "DE",
    includesCondition: Bool = true
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
              "description": "moderate rain",
              "icon": "10d"
            }
          ]
          """
        : "[]"

    let json = """
    {
      "coord": { "lon": 13.405, "lat": 52.52 },
      "weather": \(conditions),
      "main": {
        "temp": 24.4,
        "feels_like": 24.6,
        "temp_min": 23.0,
        "temp_max": 25.0,
        "pressure": 1015,
        "humidity": 64
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
