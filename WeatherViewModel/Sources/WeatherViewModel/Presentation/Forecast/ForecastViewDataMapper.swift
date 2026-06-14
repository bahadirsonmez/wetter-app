import WeatherModel

struct ForecastViewDataMapper {

    private let formatter: any ForecastFormatting

    init(formatter: any ForecastFormatting = ForecastFormatter()) {
        self.formatter = formatter
    }

    func map(_ response: ForecastResponse) -> HourlyForecastViewData {
        let sortedForecasts = response.forecasts.sorted {
            $0.timestamp < $1.timestamp
        }

        guard
            let minimumTemperature = sortedForecasts
                .map(\.temperature.temperature)
                .min(),
            let maximumTemperature = sortedForecasts
                .map(\.temperature.temperature)
                .max()
        else {
            return HourlyForecastViewData(
                days: [],
                minimumTemperature: .zero,
                maximumTemperature: .zero
            )
        }

        return HourlyForecastViewData(
            days: makeDays(
                from: sortedForecasts,
                timezoneOffset: response.location.timezoneOffset
            ),
            minimumTemperature: minimumTemperature,
            maximumTemperature: maximumTemperature
        )
    }
}

// MARK: - Helpers

private extension ForecastViewDataMapper {

    func makeDays(
        from forecasts: [HourlyForecast],
        timezoneOffset: Int
    ) -> [HourlyForecastDayViewData] {
        forecasts.reduce(into: [HourlyForecastDayViewData]()) {
            days,
            forecast in
            let item = makeItem(
                from: forecast,
                timezoneOffset: timezoneOffset
            )

            guard
                let lastDay = days.last,
                let firstItem = lastDay.items.first,
                formatter.isSameDay(
                    firstItem.id,
                    forecast.timestamp,
                    timezoneOffset: timezoneOffset
                )
            else {
                days.append(
                    HourlyForecastDayViewData(
                        id: forecast.timestamp,
                        title: formatter.dayTitle(
                            for: forecast.timestamp,
                            timezoneOffset: timezoneOffset
                        ),
                        items: [item]
                    )
                )
                return
            }

            days[days.count - 1] = HourlyForecastDayViewData(
                id: lastDay.id,
                title: lastDay.title,
                items: lastDay.items + [item]
            )
        }
    }

    func makeItem(
        from forecast: HourlyForecast,
        timezoneOffset: Int
    ) -> HourlyForecastItemViewData {
        HourlyForecastItemViewData(
            id: forecast.timestamp,
            timeText: formatter.timeText(
                for: forecast.timestamp,
                timezoneOffset: timezoneOffset
            ),
            temperatureText: formatter.temperature(
                forecast.temperature.temperature
            ),
            temperatureValue: forecast.temperature.temperature
        )
    }
}
