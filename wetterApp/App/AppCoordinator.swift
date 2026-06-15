import UIKit
import WeatherModel
import WeatherViewModel

// The app target defaults to MainActor isolation. Keep the coordinator's
// lifetime nonisolated while explicitly isolating every navigation operation.
nonisolated final class AppCoordinator {

    // MARK: - Dependencies

    let splitViewController: AppSplitViewController
    let primaryNavigationController: UINavigationController
    let secondaryNavigationController: UINavigationController

    private let weatherService: any WeatherFetching
    private let locationsStore: any LocationsStoring
    private let locationSearchService: any LocationSearching
    private let locationProviderFactory: () -> any CurrentLocationProviding

    // MARK: - Properties

    private var locationsViewModel: LocationsViewModel?

    // MARK: - Initialization

    @MainActor
    init(
        splitViewController: AppSplitViewController,
        primaryNavigationController: UINavigationController,
        secondaryNavigationController: UINavigationController,
        weatherService: any WeatherFetching,
        locationsStore: any LocationsStoring,
        locationSearchService: any LocationSearching,
        locationProviderFactory: @escaping () -> any CurrentLocationProviding
    ) {
        self.splitViewController = splitViewController
        self.primaryNavigationController = primaryNavigationController
        self.secondaryNavigationController = secondaryNavigationController
        self.weatherService = weatherService
        self.locationsStore = locationsStore
        self.locationSearchService = locationSearchService
        self.locationProviderFactory = locationProviderFactory
    }

    // MARK: - Public Methods

    @MainActor
    func start() {
        let locationsViewModel = LocationsViewModel(store: locationsStore)
        let locationsViewController = LocationsViewController(
            viewModel: locationsViewModel
        )
        self.locationsViewModel = locationsViewModel

        locationsViewController.onAddLocation = { [weak self] in
            self?.showLocationSearch()
        }
        locationsViewModel.onLocationSelected = { [weak self] identifier in
            self?.showWeather(for: identifier)
        }
        locationsViewModel.onLocationDeleted = { [weak self] id in
            self?.handleDeletedLocation(id: id)
        }

        primaryNavigationController.setViewControllers(
            [locationsViewController],
            animated: false
        )
        showInitialWeather()
    }

    @MainActor
    func sceneDidBecomeActive() {
        guard activeWeatherViewController?.source == .current else {
            return
        }
        activeWeatherViewController?.requestCurrentLocationAfterActivation()
    }

    var activeWeatherViewController: LocationWeatherViewController? {
        splitViewController.activeWeatherViewController
    }

    // MARK: - Navigation

    @MainActor
    private func showInitialWeather() {
        let snapshot = locationsStore.loadSnapshot()

        guard
            let lastViewedLocationID = snapshot.lastViewedLocationID,
            let location = snapshot.locations.first(where: {
                $0.id == lastViewedLocationID
            })
        else {
            showWeather(source: .current)
            return
        }

        showWeather(source: .saved(location))
    }

    @MainActor
    private func showWeather(
        for identifier: LocationsListItemIdentifier
    ) {
        switch identifier {
        case .current:
            showWeather(source: .current)
        case let .saved(id):
            let snapshot = locationsStore.loadSnapshot()
            guard let location = snapshot.locations.first(where: {
                $0.id == id
            }) else {
                showWeather(source: .current)
                return
            }
            showWeather(source: .saved(location))
        }
    }

    @MainActor
    private func makeWeatherViewController(
        source: WeatherLocationSource
    ) -> LocationWeatherViewController {
        let weatherViewModel = LocationWeatherViewModel(
            weatherService: weatherService
        )
        let weatherViewController = LocationWeatherViewController(
            viewModel: weatherViewModel,
            locationProvider: locationProviderFactory(),
            source: source
        )
        return weatherViewController
    }

    @MainActor
    private func showWeather(source: WeatherLocationSource) {
        splitViewController.setWeatherViewController(
            makeWeatherViewController(source: source)
        )
    }

    @MainActor
    private func showLocationSearch() {
        let searchViewModel = LocationSearchViewModel(
            searchService: locationSearchService,
            store: locationsStore
        )
        let searchViewController = LocationSearchViewController(
            viewModel: searchViewModel
        )
        searchViewController.onLocationAdded = { [weak self] in
            guard let self else {
                return
            }

            locationsViewModel?.loadLocations()
            primaryNavigationController.popViewController(animated: true)
        }
        primaryNavigationController.pushViewController(
            searchViewController,
            animated: true
        )
    }

    @MainActor
    private func handleDeletedLocation(id: UUID) {
        guard
            case let .saved(location) = activeWeatherViewController?.source,
            location.id == id
        else {
            return
        }

        showWeather(source: .current)
    }
}
