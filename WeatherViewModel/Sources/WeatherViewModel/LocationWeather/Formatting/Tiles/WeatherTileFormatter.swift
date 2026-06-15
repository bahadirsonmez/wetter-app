import Foundation

public struct WeatherTileFormatter: WeatherTileFormatting {

    // MARK: - Properties

    private let locale: Locale

    // MARK: - Initialization

    public init(locale: Locale = .current) {
        self.locale = locale
    }

    // MARK: - Formatting

    public func temperature(_ value: Double) -> String {
        "\(Int(value.rounded()))°C"
    }

    public func pressure(_ value: Int) -> String {
        "\(value) hPa"
    }

    public func windSpeed(_ value: Double) -> String {
        "\(decimal(value, maximumFractionDigits: 1)) m/s"
    }

    public func visibility(_ value: Int) -> String {
        let kilometers = Double(value) / 1_000
        return "\(decimal(kilometers, maximumFractionDigits: 1)) km"
    }

    public func percentage(_ value: Int) -> String {
        "\(value)%"
    }

    public func time(timestamp: Int, timezoneOffset: Int) -> String {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timezoneOffset: timezoneOffset)
        formatter.locale = locale
        formatter.timeZone = timezone(for: timezoneOffset)
        formatter.dateFormat = "HH:mm"
        return formatter.string(
            from: Date(timeIntervalSince1970: TimeInterval(timestamp))
        )
    }
}

// MARK: - Helpers

private extension WeatherTileFormatter {

    func decimal(
        _ value: Double,
        maximumFractionDigits: Int
    ) -> String {
        let formatter = NumberFormatter()
        formatter.locale = locale
        formatter.numberStyle = .decimal
        formatter.usesGroupingSeparator = false
        formatter.minimumFractionDigits = 0
        formatter.maximumFractionDigits = maximumFractionDigits

        return formatter.string(from: NSNumber(value: value))
            ?? String(value)
    }

    func calendar(timezoneOffset: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone(for: timezoneOffset)
        return calendar
    }

    func timezone(for offset: Int) -> TimeZone {
        TimeZone(secondsFromGMT: offset)
            ?? TimeZone(secondsFromGMT: .zero)!
    }
}
