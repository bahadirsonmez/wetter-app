import CoreLocation
import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationWeatherViewControllerTests: XCTestCase {

    func testViewDidLoadUsesLocationWeatherView() {
        let context = makeContext()

        context.viewController.loadViewIfNeeded()

        XCTAssertTrue(context.viewController.view is LocationWeatherView)
    }

    func testViewDidLoadRequestsCurrentLocation() {
        let context = makeContext()

        context.viewController.loadViewIfNeeded()

        XCTAssertEqual(context.locationProvider.requestCallCount, 1)
    }

    func testActivationAfterReturningFromSettingsRequestsLocationAgain() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewController.requestCurrentLocationAfterActivation()

        XCTAssertEqual(context.locationProvider.requestCallCount, 2)
    }

    func testLocationSuccessLoadsWeatherForCoordinate() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.locationProvider.send(
            .success(
                CLLocationCoordinate2D(
                    latitude: 52.52,
                    longitude: 13.405
                )
            )
        )

        XCTAssertEqual(context.viewModel.receivedLatitude, 52.52)
        XCTAssertEqual(context.viewModel.receivedLongitude, 13.405)
    }

    func testInitialLoadingShowsFullScreenLoadingView() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.loading)

        XCTAssertFalse(context.weatherView.loadingView.isHidden)
        XCTAssertTrue(context.weatherView.scrollView.isHidden)
        XCTAssertTrue(context.weatherView.summaryContainerView.statusView.isHidden)
    }

    func testLoadedStateDisplaysWeatherSummary() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))

        XCTAssertEqual(
            context.weatherView.summaryContainerView.summaryView.locationLabel.text,
            "Berlin"
        )
        XCTAssertFalse(context.weatherView.scrollView.isHidden)
        XCTAssertTrue(context.weatherView.loadingView.isHidden)
        XCTAssertTrue(context.weatherView.summaryContainerView.statusView.isHidden)
    }

    func testLoadedStateDisplaysTemperatureGraph() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))

        XCTAssertFalse(context.weatherView.forecastContainerView.temperatureGraphView.isHidden)
        XCTAssertTrue(context.weatherView.forecastContainerView.statusView.isHidden)
        XCTAssertEqual(
            context.weatherView.forecastContainerView.temperatureGraphView.collectionView
                .numberOfSections,
            1
        )
    }

    func testLoadedStateWithEmptyForecastDisplaysLocalUnavailableStatus() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(
            .loaded(
                LocationWeatherViewDataFixture.berlin(
                    hourlyForecast: LocationWeatherViewDataFixture.emptyForecast
                )
            )
        )

        XCTAssertEqual(
            context.weatherView.forecastContainerView.statusView.titleLabel.text,
            "Forecast unavailable"
        )
        XCTAssertFalse(context.weatherView.forecastContainerView.statusView.isHidden)
        XCTAssertFalse(context.weatherView.scrollView.isHidden)
        XCTAssertTrue(context.weatherView.summaryContainerView.statusView.isHidden)
    }

    func testRefreshSuccessUpdatesForecast() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))
        context.weatherView.refreshControl.sendActions(for: .valueChanged)

        let updatedForecast = HourlyForecastViewData(
            days: [
                HourlyForecastDayViewData(
                    id: 1_781_390_400,
                    title: "Sunday, Jun 14",
                    items: [
                        HourlyForecastItemViewData(
                            id: 1_781_398_800,
                            timeText: "15:00",
                            temperatureText: "28°C",
                            conditionText: "Clear sky",
                            temperatureValue: 28
                        )
                    ]
                )
            ],
            minimumTemperature: 28,
            maximumTemperature: 28
        )

        context.viewModel.send(
            .loaded(
                LocationWeatherViewDataFixture.berlin(
                    hourlyForecast: updatedForecast
                )
            )
        )

        let collectionView = context.weatherView.forecastContainerView.temperatureGraphView
            .collectionView
        let cell = collectionView.dataSource?.collectionView(
            collectionView,
            cellForItemAt: IndexPath(item: 0, section: 0)
        ) as? HourlyForecastCell

        XCTAssertEqual(cell?.temperatureLabel.text, "28°C")
    }

    func testInitialWeatherFailureShowsRetryStatus() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.failed(.unavailable))

        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.titleLabel.text,
            "Weather Unavailable"
        )
        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.messageLabel.text,
            LocationWeatherViewError.unavailable.message
        )
        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.actionButton.title(for: .normal),
            "Retry"
        )
        XCTAssertFalse(context.weatherView.summaryContainerView.statusView.isHidden)
        XCTAssertFalse(context.weatherView.scrollView.isHidden)
        XCTAssertTrue(context.weatherView.summaryContainerView.summaryView.isHidden)
        XCTAssertTrue(context.weatherView.forecastContainerView.isHidden)
    }

    func testWeatherRetryActionRefreshesViewModel() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.viewModel.send(.failed(.unavailable))

        context.weatherView.summaryContainerView.statusView.actionButton.sendActions(
            for: .touchUpInside
        )

        XCTAssertEqual(context.viewModel.refreshCallCount, 1)
    }

    func testPullToRefreshRefreshesViewModel() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))

        context.weatherView.refreshControl.sendActions(for: .valueChanged)

        XCTAssertEqual(context.viewModel.refreshCallCount, 1)
    }

    func testPullToRefreshBeforeLoadedDoesNotRefreshViewModel() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.weatherView.refreshControl.beginRefreshing()

        context.weatherView.refreshControl.sendActions(for: .valueChanged)

        XCTAssertEqual(context.viewModel.refreshCallCount, 0)
        XCTAssertFalse(context.weatherView.refreshControl.isRefreshing)
    }

    func testRefreshLoadingKeepsExistingSummaryVisible() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))

        context.weatherView.refreshControl.sendActions(for: .valueChanged)
        context.viewModel.send(.loading)

        XCTAssertEqual(
            context.weatherView.summaryContainerView.summaryView.locationLabel.text,
            "Berlin"
        )
        XCTAssertFalse(context.weatherView.scrollView.isHidden)
        XCTAssertTrue(context.weatherView.loadingView.isHidden)
    }

    func testRefreshSuccessEndsRefreshing() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))
        context.weatherView.refreshControl.beginRefreshing()
        context.weatherView.refreshControl.sendActions(for: .valueChanged)

        context.viewModel.send(
            .loaded(
                LocationWeatherViewDataFixture.berlin(
                    locationName: "Hamburg"
                )
            )
        )

        XCTAssertFalse(context.weatherView.refreshControl.isRefreshing)
        XCTAssertEqual(
            context.weatherView.summaryContainerView.summaryView.locationLabel.text,
            "Hamburg"
        )
    }

    func testRefreshFailureKeepsExistingSummaryVisible() {
        let context = makeContext()
        let window = UIWindow(frame: UIScreen.main.bounds)
        window.rootViewController = context.viewController
        window.makeKeyAndVisible()
        defer {
            window.isHidden = true
        }

        context.viewController.loadViewIfNeeded()
        context.viewModel.send(.loaded(LocationWeatherViewDataFixture.berlin()))
        context.weatherView.refreshControl.beginRefreshing()
        context.weatherView.refreshControl.sendActions(for: .valueChanged)

        context.viewModel.send(.failed(.unavailable))

        XCTAssertFalse(context.weatherView.refreshControl.isRefreshing)
        XCTAssertEqual(
            context.weatherView.summaryContainerView.summaryView.locationLabel.text,
            "Berlin"
        )
        XCTAssertFalse(context.weatherView.scrollView.isHidden)
        XCTAssertTrue(context.weatherView.summaryContainerView.statusView.isHidden)

        let alert = context.viewController.presentedViewController
            as? UIAlertController
        XCTAssertEqual(alert?.title, "Refresh Failed")
        XCTAssertEqual(
            alert?.message,
            LocationWeatherViewError.unavailable.message
        )
    }

    func testDeniedLocationShowsOpenSettingsStatus() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.locationProvider.send(.failure(.authorizationDenied))

        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.titleLabel.text,
            "Location Permission Required"
        )
        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.actionButton.title(for: .normal),
            "Open Settings"
        )
    }

    func testRestrictedLocationShowsExplanationWithoutAction() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.locationProvider.send(.failure(.authorizationRestricted))

        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.titleLabel.text,
            "Location Access Restricted"
        )
        XCTAssertTrue(context.weatherView.summaryContainerView.statusView.actionButton.isHidden)
    }

    func testDisabledLocationServicesShowsExplanationWithoutAction() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.locationProvider.send(.failure(.servicesDisabled))

        XCTAssertEqual(
            context.weatherView.summaryContainerView.statusView.titleLabel.text,
            "Location Services Disabled"
        )
        XCTAssertTrue(context.weatherView.summaryContainerView.statusView.actionButton.isHidden)
    }

    func testUnavailableLocationRetryRequestsLocationAgain() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        context.locationProvider.send(.failure(.locationUnavailable))

        context.weatherView.summaryContainerView.statusView.actionButton.sendActions(
            for: .touchUpInside
        )

        XCTAssertEqual(context.locationProvider.requestCallCount, 2)
    }

    // MARK: - Helpers

    private func makeContext() -> TestContext {
        let viewModel = LocationWeatherViewModelSpy()
        let locationProvider = CurrentLocationProviderSpy()
        let viewController = LocationWeatherViewController(
            viewModel: viewModel,
            locationProvider: locationProvider
        )

        return TestContext(
            viewController: viewController,
            viewModel: viewModel,
            locationProvider: locationProvider
        )
    }
}

@MainActor
private struct TestContext {

    let viewController: LocationWeatherViewController
    let viewModel: LocationWeatherViewModelSpy
    let locationProvider: CurrentLocationProviderSpy

    var weatherView: LocationWeatherView {
        guard let weatherView = viewController.view as? LocationWeatherView else {
            preconditionFailure("Expected LocationWeatherView.")
        }

        return weatherView
    }
}
