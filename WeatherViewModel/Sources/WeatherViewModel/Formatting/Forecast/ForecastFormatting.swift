public protocol ForecastFormatting: Sendable {

    func dayTitle(for timestamp: Int, timezoneOffset: Int) -> String
    func timeText(for timestamp: Int, timezoneOffset: Int) -> String
    func temperature(_ value: Double) -> String
    func capitalizedFirstLetter(_ text: String) -> String
    func isSameDay(
        _ firstTimestamp: Int,
        _ secondTimestamp: Int,
        timezoneOffset: Int
    ) -> Bool
}
