import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class AdaptiveLocationWeatherLayoutTests: XCTestCase {

    private let supportedSizes: [CGSize] = [
        CGSize(width: 390, height: 844),
        CGSize(width: 320, height: 568),
        CGSize(width: 320, height: 1_024),
        CGSize(width: 507, height: 1_024),
        CGSize(width: 834, height: 1_194),
        CGSize(width: 1_194, height: 834),
        CGSize(width: 1_366, height: 1_024)
    ]

    func testContentUsesViewportHeightWhenContentFits() throws {
        let view = makeConfiguredView(
            size: CGSize(width: 834, height: 1_194)
        )
        let contentView = try contentView(in: view)

        XCTAssertEqual(
            contentView.bounds.height,
            view.scrollView.bounds.height,
            accuracy: 0.001
        )
        XCTAssertEqual(
            view.scrollView.contentSize.height,
            view.scrollView.bounds.height,
            accuracy: 0.001
        )
    }

    func testContentDoesNotScrollWhenHeightIsConstrained() {
        let view = makeConfiguredView(
            size: CGSize(width: 320, height: 568)
        )

        XCTAssertEqual(
            view.scrollView.contentSize.height,
            view.scrollView.bounds.height,
            accuracy: 0.001
        )

        view.scrollView.contentOffset.y = 100
        view.scrollViewDidScroll(view.scrollView)

        XCTAssertEqual(view.scrollView.contentOffset.y, .zero)
    }

    func testSectionsRemainVerticallyOrderedAfterResize() {
        let view = makeConfiguredView(
            size: CGSize(width: 390, height: 844)
        )

        for size in supportedSizes {
            resize(view, to: size)

            XCTAssertLessThanOrEqual(
                view.summaryContainerView.frame.maxY,
                view.forecastContainerView.frame.minY + 0.001
            )
            XCTAssertLessThanOrEqual(
                view.forecastContainerView.frame.maxY,
                view.tilesContainerView.frame.minY + 0.001
            )
        }
    }

    func testSummaryRemainsInsideReadableBounds() throws {
        for size in supportedSizes {
            let view = makeConfiguredView(size: size)
            let contentView = try contentView(in: view)

            XCTAssertGreaterThanOrEqual(
                view.summaryContainerView.frame.minX,
                contentView.bounds.minX
            )
            XCTAssertLessThanOrEqual(
                view.summaryContainerView.frame.maxX,
                contentView.bounds.maxX
            )
        }
    }

    func testGraphMatchesContainerWidthAfterResize() {
        let view = makeConfiguredView(
            size: CGSize(width: 390, height: 844)
        )

        for size in supportedSizes {
            resize(view, to: size)

            XCTAssertEqual(
                view.forecastContainerView.temperatureGraphView.frame.width,
                view.forecastContainerView.bounds.width,
                accuracy: 0.001
            )
            XCTAssertEqual(
                view.forecastContainerView.temperatureGraphView
                    .collectionView.frame.width,
                view.forecastContainerView.bounds.width,
                accuracy: 0.001
            )
        }
    }

    func testTilesMatchContainerBoundsAfterResize() {
        let view = makeConfiguredView(
            size: CGSize(width: 390, height: 844)
        )

        for size in supportedSizes {
            resize(view, to: size)

            XCTAssertEqual(
                view.tilesContainerView.tilesView.frame,
                view.tilesContainerView.bounds
            )
        }
    }

    func testNoSectionHasNegativeHeight() {
        for size in supportedSizes {
            let view = makeConfiguredView(size: size)
            let sections = [
                view.summaryContainerView,
                view.forecastContainerView,
                view.tilesContainerView
            ]

            XCTAssertTrue(
                sections.allSatisfy { $0.frame.height >= .zero },
                "Negative section height at \(size)"
            )
        }
    }

    func testSafeAreaInsetsAreRespected() {
        let view = LocationWeatherView()
        let verticalConstraints = view.constraints.filter {
            $0.firstItem === view.scrollView
                && ($0.firstAttribute == .top
                    || $0.firstAttribute == .bottom)
        }

        XCTAssertEqual(verticalConstraints.count, 2)
        XCTAssertTrue(
            verticalConstraints.allSatisfy {
                $0.secondItem === view.safeAreaLayoutGuide
            }
        )
    }
}

// MARK: - Helpers

private extension AdaptiveLocationWeatherLayoutTests {

    func makeConfiguredView(size: CGSize) -> LocationWeatherView {
        let view = LocationWeatherView(
            frame: CGRect(origin: .zero, size: size)
        )
        let viewData = LocationWeatherViewDataFixture.berlin(
            tiles: makeTiles()
        )

        view.summaryContainerView.summaryView.configure(with: viewData)
        view.forecastContainerView.temperatureGraphView.isHidden = false
        view.forecastContainerView.temperatureGraphView.configure(
            with: viewData.hourlyForecast
        )
        view.tilesContainerView.tilesView.configure(with: viewData.tiles)
        layout(view)

        return view
    }

    func resize(_ view: LocationWeatherView, to size: CGSize) {
        view.frame.size = size
        view.setNeedsLayout()
        layout(view)
    }

    func layout(_ view: LocationWeatherView) {
        view.layoutIfNeeded()
        view.setNeedsLayout()
        view.layoutIfNeeded()
    }

    func contentView(in view: LocationWeatherView) throws -> UIView {
        try XCTUnwrap(view.summaryContainerView.superview)
    }

    func makeTiles() -> [WeatherTileViewData] {
        let identifiers: [WeatherTileIdentifier] = [
            .minimumTemperature,
            .maximumTemperature,
            .pressure,
            .wind,
            .visibility,
            .cloudCoverage,
            .sunrise,
            .sunset
        ]

        return identifiers.enumerated().map { index, identifier in
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
