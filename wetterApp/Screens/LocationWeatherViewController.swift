//
//  LocationWeatherViewController.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 11.06.26.
//

import UIKit
import WeatherViewModel

final class LocationWeatherViewController: UIViewController {

    // MARK: - Private Properties

    private let viewModel: any LocationWeatherViewModeling
    // The controller coordinates location input with weather loading, keeping
    // the ViewModel independent from CoreLocation and focused on presentation.
    private let locationProvider: any CurrentLocationProviding

    // MARK: - Initialization

    init(
        viewModel: any LocationWeatherViewModeling,
        locationProvider: any CurrentLocationProviding
    ) {
        self.viewModel = viewModel
        self.locationProvider = locationProvider
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
    }
}
