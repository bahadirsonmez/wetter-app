import UIKit
import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationSearchViewControllerTests: XCTestCase {

    func testInitialStateDisplaysSearchInstructions() {
        let context = makeContext()

        context.viewController.loadViewIfNeeded()

        XCTAssertEqual(
            (context.viewController.tableView.backgroundView as? UILabel)?.text,
            "Search for a city to add a location."
        )
    }

    func testSearchTextForwardsQueryToViewModel() throws {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()
        let searchController = try XCTUnwrap(
            context.viewController.navigationItem.searchController
        )
        searchController.searchBar.text = "Berlin"

        XCTAssertEqual(context.viewModel.receivedQueries.last, "Berlin")
    }

    func testLoadingStateDisplaysActivityIndicator() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.loading)

        let indicator = context.viewController.tableView.backgroundView
            as? UIActivityIndicatorView
        XCTAssertEqual(indicator?.isAnimating, true)
    }

    func testLoadedStateDisplaysSearchResults() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(
            .loaded([
                LocationSearchResultViewData(
                    title: "Berlin",
                    subtitle: "Berlin, DE"
                )
            ])
        )

        XCTAssertEqual(
            context.viewController.tableView.numberOfRows(inSection: 0),
            1
        )
        let cell = context.viewController.tableView(
            context.viewController.tableView,
            cellForRowAt: IndexPath(row: 0, section: 0)
        )
        XCTAssertEqual(cell.textLabel?.text, "Berlin")
        XCTAssertEqual(cell.detailTextLabel?.text, "Berlin, DE")
    }

    func testEmptyStateDisplaysMessage() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.empty)

        XCTAssertEqual(
            (context.viewController.tableView.backgroundView as? UILabel)?.text,
            "No locations found."
        )
    }

    func testFailedStateDisplaysErrorMessage() {
        let context = makeContext()
        context.viewController.loadViewIfNeeded()

        context.viewModel.send(.failed(.unavailable))

        XCTAssertEqual(
            (context.viewController.tableView.backgroundView as? UILabel)?.text,
            LocationSearchViewError.unavailable.message
        )
    }

    func testSelectingResultForwardsIndex() {
        let context = makeContext()
        context.viewModel.state = .loaded([
            LocationSearchResultViewData(
                title: "Berlin",
                subtitle: "Berlin, DE"
            )
        ])
        context.viewController.loadViewIfNeeded()

        context.viewController.tableView(
            context.viewController.tableView,
            didSelectRowAt: IndexPath(row: 0, section: 0)
        )

        XCTAssertEqual(context.viewModel.selectedIndexes, [0])
    }

    func testSuccessfulSaveInvokesLocationAddedCallback() {
        let context = makeContext()
        var callbackCount = 0
        context.viewController.onLocationAdded = {
            callbackCount += 1
        }
        context.viewController.loadViewIfNeeded()

        context.viewModel.sendLocationAdded()

        XCTAssertEqual(callbackCount, 1)
    }
}

// MARK: - Helpers

private extension LocationSearchViewControllerTests {

    struct Context {
        let viewController: LocationSearchViewController
        let viewModel: LocationSearchViewModelSpy
    }

    func makeContext() -> Context {
        let viewModel = LocationSearchViewModelSpy()
        return Context(
            viewController: LocationSearchViewController(
                viewModel: viewModel
            ),
            viewModel: viewModel
        )
    }
}
