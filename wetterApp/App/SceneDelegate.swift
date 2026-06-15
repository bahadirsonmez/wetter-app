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
    var coordinator: AppCoordinator?
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
        let navigationController = UINavigationController()
        window.rootViewController = navigationController

        do {
            let configuration = try AppConfiguration()
            let coordinator = AppCoordinator(
                navigationController: navigationController,
                weatherService: WeatherService(
                    apiKey: configuration.openWeatherAPIKey
                ),
                locationsStore: UserDefaultsLocationsStore(),
                locationSearchService: MapKitLocationSearchService(),
                locationProviderFactory: { CurrentLocationProvider() }
            )
            coordinator.start()
            self.coordinator = coordinator
        } catch {
            assertionFailure("App configuration failed: \(error)")
        }

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

        coordinator?.sceneDidBecomeActive()
    }
}
