import Foundation

public struct ForecastFormatter: ForecastFormatting {

    public init() {}

    public func dayTitle(
        for timestamp: Int,
        timezoneOffset: Int
    ) -> String {
        dateFormatter(
            format: "EEEE, MMM d",
            timezoneOffset: timezoneOffset
        ).string(from: date(for: timestamp))
    }

    public func timeText(
        for timestamp: Int,
        timezoneOffset: Int
    ) -> String {
        dateFormatter(
            format: "HH:mm",
            timezoneOffset: timezoneOffset
        ).string(from: date(for: timestamp))
    }

    public func temperature(_ value: Double) -> String {
        "\(Int(value.rounded()))°C"
    }

    public func capitalizedFirstLetter(_ text: String) -> String {
        text.prefix(1).uppercased() + String(text.dropFirst())
    }

    public func isSameDay(
        _ firstTimestamp: Int,
        _ secondTimestamp: Int,
        timezoneOffset: Int
    ) -> Bool {
        calendar(timezoneOffset: timezoneOffset).isDate(
            date(for: firstTimestamp),
            inSameDayAs: date(for: secondTimestamp)
        )
    }
}

// MARK: - Helpers

private extension ForecastFormatter {

    func date(for timestamp: Int) -> Date {
        Date(timeIntervalSince1970: TimeInterval(timestamp))
    }

    func calendar(timezoneOffset: Int) -> Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timezone(for: timezoneOffset)
        return calendar
    }

    func dateFormatter(
        format: String,
        timezoneOffset: Int
    ) -> DateFormatter {
        let formatter = DateFormatter()
        formatter.calendar = calendar(timezoneOffset: timezoneOffset)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = timezone(for: timezoneOffset)
        formatter.dateFormat = format
        return formatter
    }

    func timezone(for offset: Int) -> TimeZone {
        TimeZone(secondsFromGMT: offset)
            ?? TimeZone(secondsFromGMT: .zero)!
    }
}
