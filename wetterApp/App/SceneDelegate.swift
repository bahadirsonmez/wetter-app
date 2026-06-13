//
//  SceneDelegate.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 08.06.26.
//

import UIKit
import WeatherModel
import WeatherViewModel

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?
    private var hasBecomeActive = false

    func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene else {
            return
        }

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = makeRootViewController()
        window.makeKeyAndVisible()
        self.window = window
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        handleSceneDidBecomeActive()
    }

    func handleSceneDidBecomeActive() {
        guard hasBecomeActive else {
            hasBecomeActive = true
            return
        }

        let viewController = window?.rootViewController
            as? LocationWeatherViewController
        viewController?.requestCurrentLocationAfterActivation()
    }

    private func makeRootViewController() -> UIViewController {
        do {
            let configuration = try AppConfiguration()
            let weatherService = WeatherService(
                apiKey: configuration.openWeatherAPIKey
            )
            let viewModel = LocationWeatherViewModel(
                weatherService: weatherService
            )
            let locationProvider = CurrentLocationProvider()

            return LocationWeatherViewController(
                viewModel: viewModel,
                locationProvider: locationProvider
            )
        } catch {
            assertionFailure("App configuration failed: \(error)")
            return UIViewController()
        }
    }
}
