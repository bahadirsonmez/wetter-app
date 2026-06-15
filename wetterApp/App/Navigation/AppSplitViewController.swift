import UIKit

final class AppSplitViewController: UISplitViewController {

    // MARK: - Properties

    let primaryNavigationController: UINavigationController
    let secondaryNavigationController: UINavigationController

    var activeWeatherViewController: LocationWeatherPageViewController? {
        primaryNavigationController.viewControllers
            .compactMap { $0 as? LocationWeatherPageViewController }
            .last
            ?? secondaryNavigationController.viewControllers
                .compactMap { $0 as? LocationWeatherPageViewController }
                .last
    }

    // MARK: - Initialization

    init(
        primaryNavigationController: UINavigationController,
        secondaryNavigationController: UINavigationController
    ) {
        self.primaryNavigationController = primaryNavigationController
        self.secondaryNavigationController = secondaryNavigationController
        super.init(style: .doubleColumn)

        configureSplitView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Public Methods

    func setWeatherViewController(
        _ weatherViewController: LocationWeatherPageViewController
    ) {
        removeWeatherViewControllers(
            excluding: weatherViewController,
            from: primaryNavigationController
        )
        removeWeatherViewControllers(
            excluding: weatherViewController,
            from: secondaryNavigationController
        )

        if isCollapsed {
            secondaryNavigationController.setViewControllers(
                [],
                animated: false
            )
            appendWeatherIfNeeded(weatherViewController)
        } else {
            removeWeatherViewControllers(
                excluding: nil,
                from: primaryNavigationController
            )
            secondaryNavigationController.setViewControllers(
                [weatherViewController],
                animated: false
            )
        }
    }

    // MARK: - Setup

    private func configureSplitView() {
        preferredDisplayMode = .oneBesideSecondary
        preferredSplitBehavior = .tile
        preferredPrimaryColumnWidth = 340
        minimumPrimaryColumnWidth = 280
        maximumPrimaryColumnWidth = 420
        primaryBackgroundStyle = .sidebar
        delegate = self

        setViewController(
            primaryNavigationController,
            for: .primary
        )
        setViewController(
            secondaryNavigationController,
            for: .secondary
        )
    }

    // MARK: - Helpers

    private func appendWeatherIfNeeded(
        _ weatherViewController: LocationWeatherPageViewController
    ) {
        guard primaryNavigationController.topViewController
                !== weatherViewController
        else {
            return
        }

        primaryNavigationController.setViewControllers(
            primaryNavigationController.viewControllers
                .filter { !($0 is LocationWeatherPageViewController) }
                + [weatherViewController],
            animated: false
        )
    }

    private func moveWeatherToPrimary() {
        guard let weatherViewController = activeWeatherViewController else {
            return
        }

        secondaryNavigationController.setViewControllers(
            [],
            animated: false
        )
        appendWeatherIfNeeded(weatherViewController)
    }

    private func moveWeatherToSecondary() {
        guard let weatherViewController = activeWeatherViewController else {
            return
        }

        removeWeatherViewControllers(
            excluding: nil,
            from: primaryNavigationController
        )
        secondaryNavigationController.setViewControllers(
            [weatherViewController],
            animated: false
        )
    }

    private func removeWeatherViewControllers(
        excluding preservedViewController: LocationWeatherPageViewController?,
        from navigationController: UINavigationController
    ) {
        let filteredViewControllers = navigationController.viewControllers
            .filter { viewController in
                guard viewController is LocationWeatherPageViewController else {
                    return true
                }
                return viewController === preservedViewController
            }

        guard filteredViewControllers.count
                != navigationController.viewControllers.count
        else {
            return
        }

        navigationController.setViewControllers(
            filteredViewControllers,
            animated: false
        )
    }
}

// MARK: - UISplitViewControllerDelegate

extension AppSplitViewController: UISplitViewControllerDelegate {

    func splitViewController(
        _ splitViewController: UISplitViewController,
        topColumnForCollapsingToProposedTopColumn proposedTopColumn:
            UISplitViewController.Column
    ) -> UISplitViewController.Column {
        .secondary
    }

    func splitViewController(
        _ splitViewController: UISplitViewController,
        collapseSecondary secondaryViewController: UIViewController,
        onto primaryViewController: UIViewController
    ) -> Bool {
        moveWeatherToPrimary()
        return true
    }

    func splitViewController(
        _ splitViewController: UISplitViewController,
        separateSecondaryFrom primaryViewController: UIViewController
    ) -> UIViewController? {
        moveWeatherToSecondary()
        return secondaryNavigationController
    }
}
