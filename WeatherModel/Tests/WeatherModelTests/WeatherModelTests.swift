import XCTest
@testable import WeatherModel

final class WeatherModelTests: XCTestCase {

    func testNetworkErrorCasesAreDistinct() {
        XCTAssertNotEqual(NetworkError.invalidURL, .invalidResponse)
        XCTAssertNotEqual(NetworkError.invalidResponse, .decodingFailed)
        XCTAssertNotEqual(NetworkError.decodingFailed, .unauthorized)
    }

    func testCurrentWeatherDecoding() throws {
        let weather = try decode(CurrentWeather.self, from: currentWeatherJSON)

        XCTAssertEqual(weather.locationName, "Berlin")
        XCTAssertEqual(weather.coordinates.latitude, 52.52)
        XCTAssertEqual(weather.temperature.feelsLike, 298.74)
        XCTAssertEqual(weather.temperature.seaLevelPressure, 1015)
        XCTAssertEqual(weather.rain?.lastHour, 3.16)
        XCTAssertEqual(weather.sun.countryCode, "DE")
    }

    func testForecastResponseDecoding() throws {
        let response = try decode(ForecastResponse.self, from: forecastJSON)
        let forecast = try XCTUnwrap(response.forecasts.first)

        XCTAssertEqual(response.count, 1)
        XCTAssertEqual(response.location.name, "Berlin")
        XCTAssertEqual(forecast.timestampText, "2026-06-11 12:00:00")
        XCTAssertEqual(forecast.precipitationProbability, 0.35)
        XCTAssertEqual(forecast.rain?.lastThreeHours, 0.72)
        XCTAssertEqual(forecast.period.partOfDay, "d")
    }

    func testLocationDetailsDecoding() throws {
        let locations = try decode([LocationDetails].self, from: locationJSON)
        let location = try XCTUnwrap(locations.first)

        XCTAssertEqual(location.name, "Berlin")
        XCTAssertEqual(location.localNames?["de"], "Berlin")
        XCTAssertEqual(location.countryCode, "DE")
        XCTAssertEqual(location.state, "Berlin")
    }

    private func decode<Value: Decodable>(
        _ type: Value.Type,
        from json: String
    ) throws -> Value {
        try JSONDecoder().decode(Value.self, from: Data(json.utf8))
    }
}

private let currentWeatherJSON = """
{
  "coord": { "lon": 13.405, "lat": 52.52 },
  "weather": [
    { "id": 501, "main": "Rain", "description": "moderate rain", "icon": "10d" }
  ],
  "main": {
    "temp": 298.48,
    "feels_like": 298.74,
    "temp_min": 297.56,
    "temp_max": 300.05,
    "pressure": 1015,
    "humidity": 64,
    "sea_level": 1015,
    "grnd_level": 933
  },
  "visibility": 10000,
  "wind": { "speed": 0.62, "deg": 349, "gust": 1.18 },
  "rain": { "1h": 3.16 },
  "clouds": { "all": 100 },
  "dt": 1661870592,
  "sys": {
    "country": "DE",
    "sunrise": 1661834187,
    "sunset": 1661882248
  },
  "timezone": 7200,
  "id": 2950159,
  "name": "Berlin"
}
"""

private let forecastJSON = """
{
  "cod": "200",
  "message": 0,
  "cnt": 1,
  "list": [
    {
      "dt": 1781179200,
      "main": {
        "temp": 24.1,
        "feels_like": 24.3,
        "temp_min": 23.8,
        "temp_max": 24.1,
        "pressure": 1012,
        "sea_level": 1012,
        "grnd_level": 1008,
        "humidity": 63,
        "temp_kf": 0.3
      },
      "weather": [
        { "id": 500, "main": "Rain", "description": "light rain", "icon": "10d" }
      ],
      "clouds": { "all": 48 },
      "wind": { "speed": 4.2, "deg": 35, "gust": 6.1 },
      "visibility": 10000,
      "pop": 0.35,
      "rain": { "3h": 0.72 },
      "sys": { "pod": "d" },
      "dt_txt": "2026-06-11 12:00:00"
    }
  ],
  "city": {
    "id": 2950159,
    "name": "Berlin",
    "coord": { "lat": 52.52, "lon": 13.405 },
    "country": "DE",
    "population": 3755251,
    "timezone": 7200,
    "sunrise": 1781140440,
    "sunset": 1781195220
  }
}
"""

private let locationJSON = """
[
  {
    "name": "Berlin",
    "local_names": {
      "de": "Berlin",
      "en": "Berlin"
    },
    "lat": 52.52,
    "lon": 13.405,
    "country": "DE",
    "state": "Berlin"
  }
]
"""
