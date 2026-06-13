//
//  LocationWeatherForecastContainerView.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 13.06.2026.
//

import UIKit

final class LocationWeatherForecastContainerView: UIView {

    // MARK: - Subviews

    let temperatureGraphView = TemperatureGraphView()
    let statusView = LocationWeatherStatusView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupView() {
        [temperatureGraphView, statusView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            addSubview($0)
        }

        NSLayoutConstraint.activate([
            temperatureGraphView.topAnchor.constraint(equalTo: topAnchor),
            temperatureGraphView.leadingAnchor.constraint(equalTo: leadingAnchor),
            temperatureGraphView.trailingAnchor.constraint(equalTo: trailingAnchor),
            temperatureGraphView.bottomAnchor.constraint(equalTo: bottomAnchor),

            statusView.topAnchor.constraint(equalTo: topAnchor),
            statusView.leadingAnchor.constraint(equalTo: leadingAnchor),
            statusView.trailingAnchor.constraint(equalTo: trailingAnchor),
            statusView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
