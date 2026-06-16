import UIKit
import WeatherViewModel

final class LocationWeatherViewController: UIViewController {

    // MARK: - Private Properties

    private let viewModel: any LocationWeatherViewModeling
    private let contentView = LocationWeatherView()

    private var hasLoadedWeather = false
    private var isRefreshing = false

    var source: LocationWeatherSource {
        viewModel.source
    }

    // MARK: - Initialization

    init(viewModel: any LocationWeatherViewModeling) {
        self.viewModel = viewModel
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
        bindActions()
        render(viewModel.state)
        viewModel.loadInitialWeather()
    }

    // MARK: - Binding

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
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

    func requestCurrentLocationAfterActivation() {
        viewModel.requestCurrentLocationAfterActivation()
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
            contentView.summaryContainerView.summaryView.configure(with: viewData)
            renderForecast(viewData.hourlyForecast)
            contentView.tilesContainerView.tilesView.configure(
                with: viewData.tiles
            )
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

    // MARK: - Rendering Helpers

    private func showInitialLoading() {
        contentView.tilesContainerView.tilesView.reset()
        contentView.scrollView.isHidden = true
        contentView.summaryContainerView.statusView.isHidden = true
        contentView.summaryContainerView.statusView.onAction = nil
        contentView.loadingView.isHidden = false
    }

    private func showContent() {
        contentView.scrollView.isHidden = false
        contentView.loadingView.isHidden = true
        contentView.summaryContainerView.statusView.isHidden = true
        contentView.summaryContainerView.statusView.onAction = nil
        contentView.summaryContainerView.summaryView.isHidden = false
        contentView.forecastContainerView.isHidden = false
        contentView.tilesContainerView.isHidden = false
    }

    private func showWeatherError(_ error: LocationWeatherViewError) {
        showStatus(
            title: error.title,
            message: error.message,
            actionTitle: error.actionTitle,
            onAction: { [weak self] in
                if error.opensApplicationSettings {
                    self?.openApplicationSettings()
                } else {
                    self?.viewModel.loadInitialWeather()
                }
            }
        )
    }

    private func showStatus(
        title: String,
        message: String,
        actionTitle: String?,
        onAction: (() -> Void)?
    ) {
        contentView.summaryContainerView.statusView.configure(
            title: title,
            message: message,
            actionTitle: actionTitle
        )
        contentView.tilesContainerView.tilesView.reset()
        contentView.summaryContainerView.statusView.onAction = onAction
        contentView.scrollView.isHidden = false
        contentView.loadingView.isHidden = true
        contentView.summaryContainerView.statusView.isHidden = false
        contentView.summaryContainerView.summaryView.isHidden = true
        contentView.forecastContainerView.isHidden = true
        contentView.tilesContainerView.isHidden = true
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
    
    private func renderForecast(
        _ viewData: HourlyForecastViewData
    ) {
        let hasForecastItems = viewData.days.contains {
            !$0.items.isEmpty
        }

        contentView.forecastContainerView.temperatureGraphView.isHidden = false

        guard hasForecastItems else {
            contentView.forecastContainerView.temperatureGraphView.reset()
            contentView.forecastContainerView.statusView.configure(
                title: "Forecast unavailable",
                message: "Hourly forecast is currently unavailable.",
                actionTitle: nil
            )
            contentView.forecastContainerView.statusView.isHidden = false
            return
        }

        contentView.forecastContainerView.temperatureGraphView.configure(with: viewData)
        contentView.forecastContainerView.statusView.isHidden = true
    }
}
