import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class DynamicTypeAccessibilityTests: XCTestCase {

    private let contentSizeCategories: [UIContentSizeCategory] = [
        .large,
        .extraExtraExtraLarge,
        .accessibilityMedium,
        .accessibilityExtraExtraExtraLarge
    ]

    func testSummaryTextDoesNotClip() {
        for category in contentSizeCategories {
            let summaryView = makeSummaryView(for: category)
            let fittingSize = summaryView.systemLayoutSizeFitting(
                CGSize(
                    width: 320,
                    height: UIView.layoutFittingCompressedSize.height
                ),
                withHorizontalFittingPriority: .required,
                verticalFittingPriority: .fittingSizeLevel
            )
            summaryView.frame = CGRect(
                origin: .zero,
                size: fittingSize
            )
            summaryView.layoutIfNeeded()

            for label in visibleSummaryLabels(in: summaryView) {
                let frame = label.convert(label.bounds, to: summaryView)
                XCTAssertTrue(
                    summaryView.bounds.contains(frame),
                    "\(category.rawValue) clips \(label)"
                )
            }
        }
    }

    func testSummaryTitleRemainsVisibleInCompactStageManagerWindow() {
        let view = makeWeatherView(
            for: .accessibilityMedium,
            size: CGSize(width: 580, height: 388),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )
        let summaryView = view.summaryContainerView.summaryView
        let locationFrame = summaryView.locationLabel.convert(
            summaryView.locationLabel.bounds,
            to: view.summaryContainerView
        )

        XCTAssertFalse(summaryView.locationLabel.isHidden)
        XCTAssertGreaterThan(locationFrame.height, .zero)
        XCTAssertTrue(
            view.summaryContainerView.bounds.contains(locationFrame)
        )
        XCTAssertTrue(summaryView.feelsLikeLabel.isHidden)
        XCTAssertTrue(summaryView.humidityValueLabel.isHidden)
    }

    func testCompactStageManagerWindowPreservesGraphBeforeTiles() {
        let view = makeWeatherView(
            for: .large,
            size: CGSize(width: 580, height: 388),
            horizontalSizeClass: .regular,
            verticalSizeClass: .compact
        )
        let graphView = view.forecastContainerView.temperatureGraphView
        let visibleTileViews = view.tilesContainerView.tilesView.subviews
            .filter { !$0.isHidden && !$0.frame.isEmpty }

        XCTAssertGreaterThanOrEqual(
            graphView.bounds.height,
            graphView.intrinsicContentSize.height - 0.001
        )
        XCTAssertTrue(visibleTileViews.isEmpty)
    }

    func testGraphCellHeightIncreasesWithContentSizeCategory() {
        let baseMetrics = TemperatureGraphLayoutMetrics()
        let heights = contentSizeCategories.map {
            baseMetrics.scaled(for: $0).itemSize.height
        }

        XCTAssertEqual(heights, heights.sorted())
        XCTAssertGreaterThan(
            heights.last ?? .zero,
            heights.first ?? .zero
        )
    }

    func testCompactHeightReducesGraphSpacingWithoutShrinkingHeader() {
        let regularMetrics = TemperatureGraphLayoutMetrics().scaled(
            for: .large
        )
        let compactMetrics = regularMetrics.compactedVertically()

        XCTAssertLessThan(
            compactMetrics.contentHeight,
            regularMetrics.contentHeight
        )
        XCTAssertEqual(
            compactMetrics.headerHeight,
            regularMetrics.headerHeight
        )
        XCTAssertEqual(
            compactMetrics.itemSize.height,
            regularMetrics.itemSize.height
        )
    }

    func testStickyHeaderRemainsReadable() {
        let baseMetrics = TemperatureGraphLayoutMetrics()
        let headerView = ForecastDayHeaderView()

        XCTAssertTrue(
            headerView.titleLabel.adjustsFontForContentSizeCategory
        )
        XCTAssertTrue(headerView.titleLabel.adjustsFontSizeToFitWidth)

        for category in contentSizeCategories {
            let traits = UITraitCollection(
                preferredContentSizeCategory: category
            )
            let font = UIFont.preferredFont(
                forTextStyle: .headline,
                compatibleWith: traits
            )
            let metrics = baseMetrics.scaled(for: category)

            XCTAssertGreaterThanOrEqual(
                metrics.headerHeight,
                ceil(font.lineHeight)
            )
        }
    }

    func testTileMinimumHeightIncreasesWithContentSizeCategory() {
        let tileView = WeatherTileView()
        tileView.configure(
            with: WeatherTileViewData(
                id: .wind,
                title: "Wind",
                valueText: "2.5 m/s",
                detailText: "North-east",
                symbolName: "wind"
            )
        )
        let heights = contentSizeCategories.map {
            tileView.makeLayoutItem(
                contentSizeCategory: $0
            ).minimumHeight
        }

        XCTAssertEqual(heights, heights.sorted())
        XCTAssertGreaterThan(
            heights.last ?? .zero,
            heights.first ?? .zero
        )
    }

    func testTileFramesDoNotOverlap() {
        for category in contentSizeCategories {
            let items = makeTileViews().map {
                $0.makeLayoutItem(
                    contentSizeCategory: category
                )
            }
            let frames = WeatherTilesLayout().makeLayout(
                availableSize: CGSize(width: 507, height: 600),
                items: items
            ).itemFrames

            for firstIndex in frames.indices {
                for secondIndex in frames.indices
                    where secondIndex > firstIndex {
                    XCTAssertFalse(
                        frames[firstIndex].intersects(
                            frames[secondIndex]
                        ),
                        "\(category.rawValue) produces overlapping tiles"
                    )
                }
            }
        }
    }

    func testScreenRemainsViewportBoundAndPullToRefreshWorks() {
        for category in contentSizeCategories {
            let view = makeWeatherView(for: category)

            XCTAssertEqual(
                view.scrollView.contentSize.height,
                view.scrollView.bounds.height,
                accuracy: 0.001
            )

            view.scrollView.contentOffset.y = 100
            view.scrollViewDidScroll(view.scrollView)
            XCTAssertEqual(view.scrollView.contentOffset.y, .zero)

            view.scrollView.contentOffset.y = -100
            view.scrollViewDidScroll(view.scrollView)
            XCTAssertEqual(view.scrollView.contentOffset.y, -100)
        }
    }
}

// MARK: - Helpers

private extension DynamicTypeAccessibilityTests {

    func makeSummaryView(
        for category: UIContentSizeCategory
    ) -> LocationWeatherSummaryView {
        var view: LocationWeatherSummaryView!
        UITraitCollection(
            preferredContentSizeCategory: category
        ).performAsCurrent {
            view = LocationWeatherSummaryView()
            view.configure(
                with: LocationWeatherViewDataFixture.berlin(
                    locationName: "Berlin weather station",
                    conditionText: "Moderate rain with cloudy intervals"
                )
            )
        }
        return view
    }

    func visibleSummaryLabels(
        in view: LocationWeatherSummaryView
    ) -> [UILabel] {
        [
            view.locationLabel,
            view.temperatureLabel,
            view.conditionLabel,
            view.feelsLikeLabel,
            view.humidityTitleLabel,
            view.humidityValueLabel
        ].filter { !$0.isHidden }
    }

    func makeTileViews() -> [WeatherTileView] {
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
            let view = WeatherTileView()
            view.configure(
                with: WeatherTileViewData(
                    id: identifier,
                    title: "Weather information \(index)",
                    valueText: "Value \(index)",
                    detailText: index.isMultiple(of: 2)
                        ? "Additional detail"
                        : nil,
                    symbolName: "circle"
                )
            )
            return view
        }
    }

    func makeWeatherView(
        for category: UIContentSizeCategory,
        size: CGSize = CGSize(width: 834, height: 1_194),
        horizontalSizeClass: UIUserInterfaceSizeClass? = nil,
        verticalSizeClass: UIUserInterfaceSizeClass? = nil
    ) -> LocationWeatherView {
        var view: LocationWeatherView!
        let traits = [
            UITraitCollection(
                preferredContentSizeCategory: category
            ),
            horizontalSizeClass.map {
                UITraitCollection(horizontalSizeClass: $0)
            },
            verticalSizeClass.map {
                UITraitCollection(verticalSizeClass: $0)
            }
        ].compactMap { $0 }

        UITraitCollection(traitsFrom: traits).performAsCurrent {
            view = LocationWeatherView(
                frame: CGRect(
                    x: 0,
                    y: 0,
                    width: size.width,
                    height: size.height
                )
            )
            let viewData = LocationWeatherViewDataFixture.berlin(
                tiles: LocationWeatherViewDataFixture.tiles()
            )
            view.summaryContainerView.summaryView.configure(
                with: viewData
            )
            view.forecastContainerView.temperatureGraphView.isHidden =
                false
            view.forecastContainerView.temperatureGraphView.configure(
                with: viewData.hourlyForecast
            )
            view.forecastContainerView.temperatureGraphView.updateLayout(
                for: category,
                verticalSizeClass: verticalSizeClass
            )
            view.tilesContainerView.tilesView.configure(
                with: viewData.tiles
            )
            view.layoutIfNeeded()
        }
        return view
    }
}
