import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherTilesContainerViewTests: XCTestCase {

    func testInitializationAddsTilesView() {
        let container = LocationWeatherTilesContainerView()

        XCTAssertTrue(container.tilesView.superview === container)
        XCTAssertEqual(container.subviews, [container.tilesView])
    }

    func testLayoutSetsTilesViewFrameToBounds() {
        let container = LocationWeatherTilesContainerView(
            frame: CGRect(x: 10, y: 20, width: 390, height: 390)
        )

        container.layoutIfNeeded()

        XCTAssertEqual(container.tilesView.frame, container.bounds)
    }

    func testContainerAndTilesViewUseNoInternalConstraints() {
        let container = LocationWeatherTilesContainerView()

        XCTAssertTrue(container.constraints.isEmpty)
        XCTAssertTrue(container.tilesView.constraints.isEmpty)
        XCTAssertTrue(
            container.tilesView.translatesAutoresizingMaskIntoConstraints
        )
    }

    func testContainerDoesNotProvideIntrinsicHeight() {
        let container = LocationWeatherTilesContainerView(
            frame: CGRect(x: 0, y: 0, width: 390, height: 390)
        )
        container.tilesView.configure(with: makeTiles(count: 4))

        container.layoutIfNeeded()

        XCTAssertEqual(
            container.intrinsicContentSize.height,
            UIView.noIntrinsicMetric
        )
    }
}

// MARK: - Helpers

private extension LocationWeatherTilesContainerViewTests {

    func makeTiles(count: Int) -> [WeatherTileViewData] {
        let identifiers: [WeatherTileIdentifier] = [
            .minimumTemperature,
            .maximumTemperature,
            .pressure,
            .wind
        ]

        return identifiers.prefix(count).enumerated().map { index, identifier in
            WeatherTileViewData(
                id: identifier,
                title: "Tile \(index)",
                valueText: "Value \(index)",
                detailText: nil,
                symbolName: "circle"
            )
        }
    }
}
