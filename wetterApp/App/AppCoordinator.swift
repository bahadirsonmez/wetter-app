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

    @MainActor
    private let locationWeatherPageViewController: LocationWeatherPageViewController

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

        let weatherServiceCapture = weatherService
        let locationProviderFactoryCapture = locationProviderFactory

        self.locationWeatherPageViewController =
            LocationWeatherPageViewController(
                makeWeatherViewController: { source in
                    let weatherViewModel = LocationWeatherViewModel(
                        weatherService: weatherServiceCapture
                    )
                    let weatherViewController =
                        LocationWeatherViewController(
                            viewModel: weatherViewModel,
                            locationProvider: locationProviderFactoryCapture(),
                            source: source
                        )
                    weatherViewController.additionalSafeAreaInsets.bottom = 24
                    return weatherViewController
                }
            )
        locationWeatherPageViewController.onSourceChange = { [weak self] in
            self?.persistLastViewedSource($0)
        }
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
        guard activeWeatherViewController?.currentWeatherViewController?.source == .current else {
            return
        }
        activeWeatherViewController?.currentWeatherViewController?.requestCurrentLocationAfterActivation()
    }

    @MainActor
    var activeWeatherViewController: LocationWeatherPageViewController? {
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
    private func showWeather(source: WeatherLocationSource) {
        let snapshot = locationsStore.loadSnapshot()
        var sources: [WeatherLocationSource] = [.current]
        sources.append(contentsOf: snapshot.locations.map { .saved($0) })

        locationWeatherPageViewController.update(
            sources: sources,
            selectedSource: source
        )
        splitViewController.setWeatherViewController(
            locationWeatherPageViewController
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

            let snapshot = self.locationsStore.loadSnapshot()
            var sources: [WeatherLocationSource] = [.current]
            sources.append(contentsOf: snapshot.locations.map { .saved($0) })
            let currentSource = self.activeWeatherViewController?
                .currentWeatherViewController?.source ?? .current
            self.locationWeatherPageViewController.update(
                sources: sources,
                selectedSource: currentSource
            )

            primaryNavigationController.popViewController(animated: true)
        }
        primaryNavigationController.pushViewController(
            searchViewController,
            animated: true
        )
    }

    @MainActor
    private func handleDeletedLocation(id: UUID) {
        let snapshot = locationsStore.loadSnapshot()
        var sources: [WeatherLocationSource] = [.current]
        sources.append(contentsOf: snapshot.locations.map { .saved($0) })

        guard
            case let .saved(location) = activeWeatherViewController?
                .currentWeatherViewController?.source,
            location.id == id
        else {
            let currentSource = activeWeatherViewController?
                .currentWeatherViewController?.source ?? .current
            locationWeatherPageViewController.update(
                sources: sources,
                selectedSource: currentSource
            )
            return
        }

        showWeather(source: .current)
    }

    @MainActor
    private func persistLastViewedSource(_ source: WeatherLocationSource) {
        let snapshot = locationsStore.loadSnapshot()
        let lastViewedLocationID: UUID?

        switch source {
        case .current:
            lastViewedLocationID = nil
        case let .saved(location):
            lastViewedLocationID = location.id
        }

        try? locationsStore.saveSnapshot(
            SavedLocationsSnapshot(
                locations: snapshot.locations,
                lastViewedLocationID: lastViewedLocationID
            )
        )
    }
}
