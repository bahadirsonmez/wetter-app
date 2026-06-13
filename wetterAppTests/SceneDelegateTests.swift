import UIKit
import XCTest
@testable import wetterApp

@MainActor
final class SceneDelegateTests: XCTestCase {

    func testSecondSceneActivationRequestsCurrentLocationAgain() {
        let locationProvider = CurrentLocationProviderSpy()
        let viewController = LocationWeatherViewController(
            viewModel: LocationWeatherViewModelSpy(),
            locationProvider: locationProvider
        )
        let sceneDelegate = SceneDelegate()
        let window = UIWindow()
        window.rootViewController = viewController
        sceneDelegate.window = window
        viewController.loadViewIfNeeded()

        sceneDelegate.handleSceneDidBecomeActive()
        XCTAssertEqual(locationProvider.requestCallCount, 1)

        sceneDelegate.handleSceneDidBecomeActive()
        XCTAssertEqual(locationProvider.requestCallCount, 2)
    }
}
