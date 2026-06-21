import XCTest
@testable import WeatherViewModel

final class ForecastViewDataMapperTests: XCTestCase {

    private let mapper = ForecastViewDataMapper()

    func testMapSortsForecastsByTimestamp() throws {
        let response = WeatherViewModelFixtures.forecastResponse(
            samples: [
                (1_781_355_600, 26, "clear sky"),
                (1_781_334_000, 22, "light rain"),
                (1_781_344_800, 24, "scattered clouds")
            ]
        )

        let viewData = mapper.map(response)
        let items = try XCTUnwrap(viewData.days.first?.items)

        XCTAssertEqual(
            items.map(\.id),
            [1_781_334_000, 1_781_344_800, 1_781_355_600]
        )
    }

    func testMapGroupsForecastsByLocalCalendarDay() {
        let response = WeatherViewModelFixtures.forecastResponse(
            samples: [
                (1_781_290_800, 20, "clear sky"),
                (1_781_301_600, 21, "clear sky"),
                (1_781_312_400, 22, "clear sky")
            ],
            timezoneOffset: 7_200
        )

        let viewData = mapper.map(response)

        XCTAssertEqual(viewData.days.count, 2)
        XCTAssertEqual(viewData.days[0].items.count, 1)
        XCTAssertEqual(viewData.days[1].items.count, 2)
        XCTAssertEqual(viewData.days[1].title, "13 June")
    }

    func testMapCreatesFormattedItems() throws {
        let response = WeatherViewModelFixtures.forecastResponse()

        let item = try XCTUnwrap(mapper.map(response).days.first?.items.first)

        XCTAssertEqual(item.id, 1_781_355_600)
        XCTAssertEqual(item.timeText, "15:00")
        XCTAssertEqual(item.temperatureText, "24°C")
        XCTAssertEqual(item.temperatureValue, 24.4)
    }

    func testMapCalculatesTemperatureRange() {
        let response = WeatherViewModelFixtures.forecastResponse(
            samples: [
                (1_781_334_000, -2.6, "snow"),
                (1_781_344_800, 24.4, "clear sky")
            ]
        )

        let viewData = mapper.map(response)

        XCTAssertEqual(viewData.minimumTemperature, -2.6)
        XCTAssertEqual(viewData.maximumTemperature, 24.4)
    }

    func testMapEmptyForecastReturnsEmptyViewData() {
        let response = WeatherViewModelFixtures.forecastResponse(samples: [])

        let viewData = mapper.map(response)

        XCTAssertTrue(viewData.days.isEmpty)
        XCTAssertEqual(viewData.minimumTemperature, .zero)
        XCTAssertEqual(viewData.maximumTemperature, .zero)
    }

    func testMapEqualTemperaturesPreservesZeroRangeForCenteredLayout() {
        let response = WeatherViewModelFixtures.forecastResponse(
            samples: [
                (1_781_334_000, 20, "clear sky"),
                (1_781_344_800, 20, "clear sky")
            ]
        )

        let viewData = mapper.map(response)

        XCTAssertEqual(viewData.minimumTemperature, 20)
        XCTAssertEqual(viewData.maximumTemperature, 20)
    }
}
