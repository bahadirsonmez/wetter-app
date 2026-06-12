public struct LocationWeatherViewData: Equatable, Sendable {

    public let locationName: String
    public let countryCode: String
    public let temperatureText: String
    public let feelsLikeText: String
    public let humidityText: String
    public let conditionText: String
    public let conditionIconName: String?

    public init(
        locationName: String,
        countryCode: String,
        temperatureText: String,
        feelsLikeText: String,
        humidityText: String,
        conditionText: String,
        conditionIconName: String?
    ) {
        self.locationName = locationName
        self.countryCode = countryCode
        self.temperatureText = temperatureText
        self.feelsLikeText = feelsLikeText
        self.humidityText = humidityText
        self.conditionText = conditionText
        self.conditionIconName = conditionIconName
    }
}
