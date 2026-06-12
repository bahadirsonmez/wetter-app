import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherSummaryViewTests: XCTestCase {

    func testConfigureDisplaysViewData() {
        let view = LocationWeatherSummaryView()

        view.configure(with: makeViewData())

        XCTAssertEqual(view.locationLabel.text, "Berlin")
        XCTAssertEqual(view.countryCodeLabel.text, "DE")
        XCTAssertEqual(view.temperatureLabel.text, "24°C")
        XCTAssertEqual(view.conditionLabel.text, "Moderate rain")
        XCTAssertEqual(view.feelsLikeLabel.text, "Feels like 25°C")
        XCTAssertEqual(view.humidityTitleLabel.text, "Humidity")
        XCTAssertEqual(view.humidityValueLabel.text, "64%")
        XCTAssertFalse(view.countryCodeLabel.isHidden)
        XCTAssertFalse(view.conditionLabel.isHidden)
    }

    func testConfigureHidesOptionalLabelsWhenValuesAreMissing() {
        let view = LocationWeatherSummaryView()

        view.configure(
            with: makeViewData(
                countryCode: nil,
                conditionText: nil
            )
        )

        XCTAssertTrue(view.countryCodeLabel.isHidden)
        XCTAssertTrue(view.conditionLabel.isHidden)
    }

    func testResetClearsDisplayedValues() {
        let view = LocationWeatherSummaryView()
        view.configure(with: makeViewData())

        view.reset()

        XCTAssertNil(view.locationLabel.text)
        XCTAssertNil(view.countryCodeLabel.text)
        XCTAssertNil(view.temperatureLabel.text)
        XCTAssertNil(view.conditionLabel.text)
        XCTAssertNil(view.feelsLikeLabel.text)
        XCTAssertEqual(view.humidityTitleLabel.text, "Humidity")
        XCTAssertNil(view.humidityValueLabel.text)
        XCTAssertTrue(view.countryCodeLabel.isHidden)
        XCTAssertTrue(view.conditionLabel.isHidden)
    }

    func testUpdateLayoutForCompactWidthHidesAdditionalInformation() {
        let view = LocationWeatherSummaryView()

        view.updateLayout(for: .compact)

        XCTAssertTrue(view.feelsLikeLabel.isHidden)
        XCTAssertTrue(view.humidityTitleLabel.isHidden)
        XCTAssertTrue(view.humidityValueLabel.isHidden)
    }

    func testUpdateLayoutForRegularWidthShowsAdditionalInformation() {
        let view = LocationWeatherSummaryView()

        view.updateLayout(for: .regular)

        XCTAssertFalse(view.feelsLikeLabel.isHidden)
        XCTAssertFalse(view.humidityTitleLabel.isHidden)
        XCTAssertFalse(view.humidityValueLabel.isHidden)
    }

    func testLabelsSupportDynamicType() {
        let view = LocationWeatherSummaryView()
        let labels = [
            view.locationLabel,
            view.countryCodeLabel,
            view.temperatureLabel,
            view.conditionLabel,
            view.feelsLikeLabel,
            view.humidityTitleLabel,
            view.humidityValueLabel
        ]

        labels.forEach {
            XCTAssertTrue($0.adjustsFontForContentSizeCategory)
            XCTAssertEqual($0.numberOfLines, 0)
        }
    }

    // MARK: - Helpers

    private func makeViewData(
        countryCode: String? = "DE",
        conditionText: String? = "Moderate rain"
    ) -> LocationWeatherViewData {
        LocationWeatherViewData(
            locationName: "Berlin",
            countryCode: countryCode,
            temperatureText: "24°C",
            feelsLikeText: "Feels like 25°C",
            humidityText: "64%",
            conditionText: conditionText,
            conditionIconName: "10d"
        )
    }
}
