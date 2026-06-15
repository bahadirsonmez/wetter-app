import Foundation
import UIKit
import WeatherViewModel
import XCTest
@testable import wetterApp

@MainActor
final class LocationsViewControllerTests: XCTestCase {

    func testViewDidLoadLoadsLocationsAndConfiguresNavigation() {
        let context = makeContext()

        context.viewController.loadViewIfNeeded()

        XCTAssertEqual(context.viewModel.loadLocationsCallCount, 1)
        XCTAssertEqual(context.viewController.title, "Locations")
        XCTAssertNotNil(context.viewController.navigationItem.leftBarButtonItem)
        XCTAssertNotNil(context.viewController.navigationItem.rightBarButtonItem)
    }

    func testTableViewDisplaysExpectedRowsAndContent() {
        let context = makeContext()
        context.viewModel.items = makeItems()

        context.viewController.loadViewIfNeeded()

        XCTAssertEqual(
            context.viewController.tableView.numberOfRows(inSection: 0),
            3
        )
        XCTAssertEqual(cell(in: context, row: 0).textLabel?.text, "Current Location")
        XCTAssertEqual(cell(in: context, row: 1).textLabel?.text, "Berlin")
        XCTAssertEqual(
            cell(in: context, row: 1).detailTextLabel?.text,
            "Berlin, DE"
        )
    }

    func testSelectingRowForwardsExpectedIdentifier() {
        let context = makeContext()
        context.viewModel.items = makeItems()
        context.viewController.loadViewIfNeeded()

        context.viewController.tableView(
            context.viewController.tableView,
            didSelectRowAt: IndexPath(row: 1, section: 0)
        )

        XCTAssertEqual(
            context.viewModel.selectedIdentifiers,
            [.saved(berlinID)]
        )
    }

    func testSwipeDeleteIsAvailableOnlyForSavedRows() {
        let context = makeContext()
        context.viewModel.items = makeItems()
        context.viewController.loadViewIfNeeded()

        XCTAssertFalse(
            context.viewController.tableView(
                context.viewController.tableView,
                canEditRowAt: IndexPath(row: 0, section: 0)
            )
        )
        XCTAssertTrue(
            context.viewController.tableView(
                context.viewController.tableView,
                canEditRowAt: IndexPath(row: 1, section: 0)
            )
        )
    }

    func testSwipeDeleteForwardsSavedLocationID() {
        let context = makeContext()
        context.viewModel.items = makeItems()
        context.viewController.loadViewIfNeeded()

        context.viewController.tableView(
            context.viewController.tableView,
            commit: .delete,
            forRowAt: IndexPath(row: 1, section: 0)
        )

        XCTAssertEqual(context.viewModel.deletedLocationIDs, [berlinID])
    }

    func testCurrentLocationCannotBeMoved() {
        let context = makeContext()
        context.viewModel.items = makeItems()
        context.viewController.loadViewIfNeeded()

        XCTAssertFalse(
            context.viewController.tableView(
                context.viewController.tableView,
                canMoveRowAt: IndexPath(row: 0, section: 0)
            )
        )
        XCTAssertTrue(
            context.viewController.tableView(
                context.viewController.tableView,
                canMoveRowAt: IndexPath(row: 1, section: 0)
            )
        )
    }

    func testMoveUsesSavedLocationIndexes() {
        let context = makeContext()
        context.viewModel.items = makeItems()
        context.viewController.loadViewIfNeeded()

        context.viewController.tableView(
            context.viewController.tableView,
            moveRowAt: IndexPath(row: 1, section: 0),
            to: IndexPath(row: 2, section: 0)
        )

        XCTAssertEqual(context.viewModel.receivedMoves.first?.from, 0)
        XCTAssertEqual(context.viewModel.receivedMoves.first?.to, 1)
    }

    func testAddButtonInvokesCallback() {
        let context = makeContext()
        var callbackCount = 0
        context.viewController.onAddLocation = {
            callbackCount += 1
        }
        context.viewController.loadViewIfNeeded()

        let addButton = context.viewController.navigationItem.rightBarButtonItem
        guard let action = addButton?.action else {
            return XCTFail("Expected add button action.")
        }
        UIApplication.shared.sendAction(
            action,
            to: addButton?.target,
            from: addButton,
            for: nil
        )

        XCTAssertEqual(callbackCount, 1)
    }
}

// MARK: - Helpers

private extension LocationsViewControllerTests {

    static let berlinID = UUID()
    static let hamburgID = UUID()

    var berlinID: UUID { Self.berlinID }
    var hamburgID: UUID { Self.hamburgID }

    struct Context {
        let viewController: LocationsViewController
        let viewModel: LocationsViewModelSpy
    }

    func makeContext() -> Context {
        let viewModel = LocationsViewModelSpy()
        return Context(
            viewController: LocationsViewController(viewModel: viewModel),
            viewModel: viewModel
        )
    }

    func makeItems() -> [LocationsListItemViewData] {
        [
            LocationsListItemViewData(
                identifier: .current,
                title: "Current Location",
                subtitle: nil,
                isDeletable: false,
                isMovable: false
            ),
            LocationsListItemViewData(
                identifier: .saved(berlinID),
                title: "Berlin",
                subtitle: "Berlin, DE",
                isDeletable: true,
                isMovable: true
            ),
            LocationsListItemViewData(
                identifier: .saved(hamburgID),
                title: "Hamburg",
                subtitle: "Hamburg, DE",
                isDeletable: true,
                isMovable: true
            )
        ]
    }

    func cell(
        in context: Context,
        row: Int
    ) -> UITableViewCell {
        context.viewController.tableView(
            context.viewController.tableView,
            cellForRowAt: IndexPath(row: row, section: 0)
        )
    }
}
