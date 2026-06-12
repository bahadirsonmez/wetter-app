public protocol LocationWeatherFormatting: Sendable {

    func rounded(_ value: Double) -> String
    func temperature(_ value: Double) -> String
    func percentage(_ value: Int) -> String
    func capitalizedFirstLetter(_ text: String) -> String
}
