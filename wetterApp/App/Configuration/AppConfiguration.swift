import Foundation

struct AppConfiguration {

    let openWeatherAPIKey: String

    init(bundle: Bundle = .main) throws {
        try self.init(infoDictionary: bundle.infoDictionary ?? [:])
    }

    init(infoDictionary: [String: Any]) throws {
        guard
            let apiKey = infoDictionary["OPEN_WEATHER_API_KEY"] as? String
        else {
            throw AppConfigurationError.missingOpenWeatherAPIKey
        }

        let trimmedAPIKey = apiKey.trimmingCharacters(
            in: .whitespacesAndNewlines
        )

        guard
            !trimmedAPIKey.isEmpty,
            trimmedAPIKey != "$(OPEN_WEATHER_API_KEY)"
        else {
            throw AppConfigurationError.missingOpenWeatherAPIKey
        }

        openWeatherAPIKey = trimmedAPIKey
    }
}
