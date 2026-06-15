import WeatherModel

struct WeatherTileViewDataMapper {

    // MARK: - Properties

    private let formatter: any WeatherTileFormatting

    // MARK: - Initialization

    init(formatter: any WeatherTileFormatting = WeatherTileFormatter()) {
        self.formatter = formatter
    }

    // MARK: - Mapping

    func map(_ weather: CurrentWeather) -> [WeatherTileViewData] {
        var tiles = [
            makeTile(
                id: .minimumTemperature,
                title: "Minimum",
                valueText: formatter.temperature(
                    weather.temperature.minimumTemperature
                ),
                symbolName: "thermometer"
            ),
            makeTile(
                id: .maximumTemperature,
                title: "Maximum",
                valueText: formatter.temperature(
                    weather.temperature.maximumTemperature
                ),
                symbolName: "thermometer"
            ),
            makeTile(
                id: .pressure,
                title: "Pressure",
                valueText: formatter.pressure(weather.temperature.pressure),
                symbolName: "gauge"
            ),
            makeTile(
                id: .wind,
                title: "Wind",
                valueText: formatter.windSpeed(weather.wind.speed),
                symbolName: "wind"
            )
        ]

        if let visibility = weather.visibility {
            tiles.append(
                makeTile(
                    id: .visibility,
                    title: "Visibility",
                    valueText: formatter.visibility(visibility),
                    symbolName: "eye"
                )
            )
        }

        tiles.append(
            contentsOf: [
                makeTile(
                    id: .cloudCoverage,
                    title: "Cloud cover",
                    valueText: formatter.percentage(
                        weather.clouds.coverage
                    ),
                    symbolName: "cloud"
                ),
                makeTile(
                    id: .sunrise,
                    title: "Sunrise",
                    valueText: formatter.time(
                        timestamp: weather.sun.sunriseTime,
                        timezoneOffset: weather.timezoneOffset
                    ),
                    symbolName: "sunrise"
                ),
                makeTile(
                    id: .sunset,
                    title: "Sunset",
                    valueText: formatter.time(
                        timestamp: weather.sun.sunsetTime,
                        timezoneOffset: weather.timezoneOffset
                    ),
                    symbolName: "sunset"
                )
            ]
        )

        return tiles
    }
}

// MARK: - Helpers

private extension WeatherTileViewDataMapper {

    func makeTile(
        id: WeatherTileIdentifier,
        title: String,
        valueText: String,
        symbolName: String
    ) -> WeatherTileViewData {
        WeatherTileViewData(
            id: id,
            title: title,
            valueText: valueText,
            detailText: nil,
            symbolName: symbolName
        )
    }
}
