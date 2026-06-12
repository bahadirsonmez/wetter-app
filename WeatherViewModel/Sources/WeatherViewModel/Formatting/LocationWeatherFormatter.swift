public struct LocationWeatherFormatter: LocationWeatherFormatting {

    public init() {}

    public func rounded(_ value: Double) -> String {
        "\(Int(value.rounded()))"
    }

    public func temperature(_ value: Double) -> String {
        "\(rounded(value))°C"
    }

    public func percentage(_ value: Int) -> String {
        "\(value)%"
    }

    public func capitalizedFirstLetter(_ text: String) -> String {
        text.prefix(1).uppercased() + String(text.dropFirst())
    }
}
