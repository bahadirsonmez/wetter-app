public protocol WeatherTileFormatting: Sendable {

    func temperature(_ value: Double) -> String
    func pressure(_ value: Int) -> String
    func windSpeed(_ value: Double) -> String
    func visibility(_ value: Int) -> String
    func percentage(_ value: Int) -> String
    func time(timestamp: Int, timezoneOffset: Int) -> String
}
