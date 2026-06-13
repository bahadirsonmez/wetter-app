//
//  LocationWeatherViewController.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 11.06.26.
//

import CoreLocation
import UIKit
import WeatherViewModel

final class LocationWeatherViewController: UIViewController {

    // MARK: - Private Properties

    private let viewModel: any LocationWeatherViewModeling
    // The controller coordinates location input with weather loading, keeping
    // the ViewModel independent from CoreLocation and focused on presentation.
    private let locationProvider: any CurrentLocationProviding
    private let contentView = LocationWeatherView()

    private var hasLoadedWeather = false
    private var isRefreshing = false

    // MARK: - Initialization

    init(
        viewModel: any LocationWeatherViewModeling,
        locationProvider: any CurrentLocationProviding
    ) {
        self.viewModel = viewModel
        self.locationProvider = locationProvider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func loadView() {
        view = contentView
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        bindLocationProvider()
        bindActions()
        render(viewModel.state)
        requestInitialLocation()
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
    }

    private func bindLocationProvider() {
        locationProvider.onLocationResult = { [weak self] result in
            guard let self else {
                return
            }

            switch result {
            case let .success(coordinate):
                viewModel.loadWeather(
                    latitude: coordinate.latitude,
                    longitude: coordinate.longitude
                )
            case let .failure(error):
                renderLocationError(error)
            }
        }
    }

    private func bindActions() {
        contentView.refreshControl.addTarget(
            self,
            action: #selector(handleRefresh),
            for: .valueChanged
        )
    }

    // MARK: - Actions

    private func requestInitialLocation() {
        locationProvider.requestCurrentLocation()
    }

    func requestCurrentLocationAfterActivation() {
        locationProvider.requestCurrentLocation()
    }

    @objc
    private func handleRefresh() {
        guard hasLoadedWeather else {
            contentView.refreshControl.endRefreshing()
            return
        }

        isRefreshing = true
        viewModel.refresh()
    }

    private func openApplicationSettings() {
        guard
            let settingsURL = URL(
                string: UIApplication.openSettingsURLString
            ),
            UIApplication.shared.canOpenURL(settingsURL)
        else {
            return
        }

        UIApplication.shared.open(settingsURL)
    }

    // MARK: - Rendering

    private func render(_ state: LocationWeatherViewState) {
        switch state {
        case .idle:
            showContent()

        case .loading:
            if isRefreshing {
                showContent()
            } else {
                showInitialLoading()
            }

        case let .loaded(viewData):
            hasLoadedWeather = true
            contentView.summaryView.configure(with: viewData)
            renderForecast(viewData.hourlyForecast)
            finishRefreshing()
            showContent()

        case let .failed(error):
            let shouldPreserveSummary = isRefreshing && hasLoadedWeather
            finishRefreshing()

            if shouldPreserveSummary {
                showContent()
                showRefreshError(error)
            } else {
                showWeatherError(error)
            }
        }
    }

    private func renderLocationError(_ error: CurrentLocationError) {
        finishRefreshing()

        switch error {
        case .servicesDisabled:
            showStatus(
                title: "Location Services Disabled",
                message: """
                Turn on Location Services to see weather for your current \
                location.
                """,
                actionTitle: nil,
                onAction: nil
            )

        case .authorizationDenied:
            showStatus(
                title: "Location Permission Required",
                message: """
                Allow location access in Settings to see weather for your \
                current location.
                """,
                actionTitle: "Open Settings",
                onAction: { [weak self] in
                    self?.openApplicationSettings()
                }
            )

        case .authorizationRestricted:
            showStatus(
                title: "Location Access Restricted",
                message: "Location access is restricted on this device.",
                actionTitle: nil,
                onAction: nil
            )

        case .locationUnavailable:
            showStatus(
                title: "Location Unavailable",
                message: "Your current location could not be determined.",
                actionTitle: "Retry",
                onAction: { [weak self] in
                    self?.requestInitialLocation()
                }
            )
        }
    }

    // MARK: - Rendering Helpers

    private func showInitialLoading() {
        contentView.scrollView.isHidden = true
        contentView.statusView.isHidden = true
        contentView.statusView.onAction = nil
        contentView.loadingView.isHidden = false
    }

    private func showContent() {
        contentView.scrollView.isHidden = false
        contentView.loadingView.isHidden = true
        contentView.statusView.isHidden = true
        contentView.statusView.onAction = nil
    }

    private func showWeatherError(_ error: LocationWeatherViewError) {
        showStatus(
            title: "Weather Unavailable",
            message: error.message,
            actionTitle: "Retry",
            onAction: { [weak self] in
                self?.viewModel.refresh()
            }
        )
    }

    private func showStatus(
        title: String,
        message: String,
        actionTitle: String?,
        onAction: (() -> Void)?
    ) {
        contentView.statusView.configure(
            title: title,
            message: message,
            actionTitle: actionTitle
        )
        contentView.statusView.onAction = onAction
        contentView.scrollView.isHidden = true
        contentView.loadingView.isHidden = true
        contentView.statusView.isHidden = false
    }

    private func showRefreshError(_ error: LocationWeatherViewError) {
        guard presentedViewController == nil else {
            return
        }

        let alert = UIAlertController(
            title: "Refresh Failed",
            message: error.message,
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }

    private func finishRefreshing() {
        isRefreshing = false
        contentView.refreshControl.endRefreshing()
    }
    
    // TODO: - Move it to the configuration function in contentview
    private func renderForecast(
        _ viewData: HourlyForecastViewData
    ) {
        let hasForecastItems = viewData.days.contains {
            !$0.items.isEmpty
        }

        contentView.temperatureGraphView.isHidden = false

        guard hasForecastItems else {
            contentView.temperatureGraphView.reset()
            contentView.forecastStatusView.configure(
                title: "Forecast unavailable",
                message: "Hourly forecast is currently unavailable.",
                actionTitle: nil
            )
            contentView.forecastStatusView.isHidden = false
            return
        }

        contentView.temperatureGraphView.configure(with: viewData)
        contentView.forecastStatusView.isHidden = true
    }
}
