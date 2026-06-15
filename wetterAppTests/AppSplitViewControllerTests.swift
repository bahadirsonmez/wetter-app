import UIKit
import XCTest
@testable import wetterApp

@MainActor
final class AppSplitViewControllerTests: XCTestCase {

    func testConfiguresDoubleColumnSplitView() {
        let context = makeContext()

        XCTAssertEqual(context.splitViewController.style, .doubleColumn)
        XCTAssertEqual(
            context.splitViewController.preferredDisplayMode,
            .oneBesideSecondary
        )
        XCTAssertEqual(
            context.splitViewController.preferredSplitBehavior,
            .tile
        )
        XCTAssertEqual(
            context.splitViewController.preferredPrimaryColumnWidth,
            340
        )
        XCTAssertEqual(
            context.splitViewController.minimumPrimaryColumnWidth,
            280
        )
        XCTAssertEqual(
            context.splitViewController.maximumPrimaryColumnWidth,
            420
        )
        XCTAssertEqual(
            context.splitViewController.primaryBackgroundStyle,
            .sidebar
        )
    }

    func testAssignsPrimaryAndSecondaryNavigationControllers() {
        let context = makeContext()

        XCTAssertTrue(
            context.splitViewController.viewController(for: .primary)
                === context.primaryNavigationController
        )
        XCTAssertTrue(
            context.splitViewController.viewController(for: .secondary)
                === context.secondaryNavigationController
        )
    }

    func testSetWeatherPlacesControllerInSecondary() {
        let context = makeContext()
        let weatherViewController = makeWeatherViewController()

        context.splitViewController.setWeatherViewController(
            weatherViewController
        )

        XCTAssertEqual(
            context.secondaryNavigationController.viewControllers.count,
            1
        )
        XCTAssertTrue(
            context.secondaryNavigationController.topViewController
                === weatherViewController
        )
        XCTAssertTrue(
            context.splitViewController.activeWeatherViewController
                === weatherViewController
        )
    }

    func testCollapseMovesSameWeatherControllerToPrimary() {
        let context = makeContext()
        let locationsViewController = UIViewController()
        let searchViewController = UIViewController()
        let weatherViewController = makeWeatherViewController()
        context.primaryNavigationController.setViewControllers(
            [locationsViewController, searchViewController],
            animated: false
        )
        context.splitViewController.setWeatherViewController(
            weatherViewController
        )

        let handled = context.splitViewController.splitViewController(
            context.splitViewController,
            collapseSecondary: context.secondaryNavigationController,
            onto: context.primaryNavigationController
        )

        XCTAssertTrue(handled)
        XCTAssertEqual(
            context.primaryNavigationController.viewControllers.count,
            3
        )
        XCTAssertTrue(
            context.primaryNavigationController.viewControllers[0]
                === locationsViewController
        )
        XCTAssertTrue(
            context.primaryNavigationController.viewControllers[1]
                === searchViewController
        )
        XCTAssertTrue(
            context.primaryNavigationController.viewControllers[2]
                === weatherViewController
        )
        XCTAssertTrue(
            context.secondaryNavigationController.viewControllers.isEmpty
        )
    }

    func testExpandMovesSameWeatherControllerBackToSecondary() {
        let context = makeContext()
        let locationsViewController = UIViewController()
        let weatherViewController = makeWeatherViewController()
        context.primaryNavigationController.setViewControllers(
            [locationsViewController],
            animated: false
        )
        context.splitViewController.setWeatherViewController(
            weatherViewController
        )
        _ = context.splitViewController.splitViewController(
            context.splitViewController,
            collapseSecondary: context.secondaryNavigationController,
            onto: context.primaryNavigationController
        )

        let separatedViewController =
            context.splitViewController.splitViewController(
                context.splitViewController,
                separateSecondaryFrom: context.primaryNavigationController
            )

        XCTAssertTrue(
            separatedViewController
                === context.secondaryNavigationController
        )
        XCTAssertEqual(
            context.primaryNavigationController.viewControllers.count,
            1
        )
        XCTAssertTrue(
            context.primaryNavigationController.topViewController
                === locationsViewController
        )
        XCTAssertTrue(
            context.secondaryNavigationController.topViewController
                === weatherViewController
        )
    }

    func testRepeatedCollapseAndExpandDoNotDuplicateWeatherController() {
        let context = makeContext()
        let locationsViewController = UIViewController()
        let weatherViewController = makeWeatherViewController()
        context.primaryNavigationController.setViewControllers(
            [locationsViewController],
            animated: false
        )
        context.splitViewController.setWeatherViewController(
            weatherViewController
        )

        for _ in 0..<3 {
            _ = context.splitViewController.splitViewController(
                context.splitViewController,
                collapseSecondary: context.secondaryNavigationController,
                onto: context.primaryNavigationController
            )
            _ = context.splitViewController.splitViewController(
                context.splitViewController,
                separateSecondaryFrom: context.primaryNavigationController
            )
        }

        let allViewControllers =
            context.primaryNavigationController.viewControllers
            + context.secondaryNavigationController.viewControllers
        XCTAssertEqual(
            allViewControllers.filter {
                $0 === weatherViewController
            }.count,
            1
        )
    }

    func testCollapsePrefersSecondaryColumn() {
        let context = makeContext()

        let topColumn = context.splitViewController.splitViewController(
            context.splitViewController,
            topColumnForCollapsingToProposedTopColumn: .primary
        )

        XCTAssertEqual(topColumn, .secondary)
    }
}

// MARK: - Helpers

private extension AppSplitViewControllerTests {

    struct Context {
        let splitViewController: AppSplitViewController
        let primaryNavigationController: UINavigationController
        let secondaryNavigationController: UINavigationController
    }

    func makeContext() -> Context {
        let primaryNavigationController = UINavigationController()
        let secondaryNavigationController = UINavigationController()
        return Context(
            splitViewController: AppSplitViewController(
                primaryNavigationController: primaryNavigationController,
                secondaryNavigationController: secondaryNavigationController
            ),
            primaryNavigationController: primaryNavigationController,
            secondaryNavigationController: secondaryNavigationController
        )
    }

    func makeWeatherViewController() -> LocationWeatherPageViewController {
        LocationWeatherPageViewController(
            makeWeatherViewController: { source in
                LocationWeatherViewController(
                    viewModel: LocationWeatherViewModelSpy(),
                    locationProvider: CurrentLocationProviderSpy(),
                    source: source
                )
            }
        )
    }
}
