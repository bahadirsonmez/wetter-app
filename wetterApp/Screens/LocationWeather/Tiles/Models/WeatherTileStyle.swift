import UIKit
import WeatherViewModel

struct WeatherTileStyle {

    let backgroundColor: UIColor
    let foregroundColor: UIColor
    let symbolName: String

    init(identifier: WeatherTileIdentifier) {
        switch identifier {
        case .minimumTemperature:
            backgroundColor = .systemBlue
            foregroundColor = .white
            symbolName = "thermometer"
        case .maximumTemperature:
            backgroundColor = .systemRed
            foregroundColor = .white
            symbolName = "thermometer"
        case .pressure:
            backgroundColor = .systemIndigo
            foregroundColor = .white
            symbolName = "gauge"
        case .wind:
            backgroundColor = .systemTeal
            foregroundColor = .white
            symbolName = "wind"
        case .visibility:
            backgroundColor = .systemPurple
            foregroundColor = .white
            symbolName = "eye"
        case .cloudCoverage:
            backgroundColor = .systemGray
            foregroundColor = .white
            symbolName = "cloud"
        case .sunrise:
            backgroundColor = .systemOrange
            foregroundColor = .label
            symbolName = "sunrise"
        case .sunset:
            backgroundColor = .systemPink
            foregroundColor = .white
            symbolName = "sunset"
        }
    }
}
