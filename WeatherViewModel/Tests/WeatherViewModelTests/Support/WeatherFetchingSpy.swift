import Foundation
import WeatherModel

final class WeatherFetchingSpy: WeatherFetching, @unchecked Sendable {

    // MARK: - Recorded Values

    private(set) var fetchCallCount: Int {
        get { lock.withLock { _fetchCallCount } }
        set { lock.withLock { _fetchCallCount = newValue } }
    }

    private(set) var receivedLatitude: Double? {
        get { lock.withLock { _receivedLatitude } }
        set { lock.withLock { _receivedLatitude = newValue } }
    }

    private(set) var receivedLongitude: Double? {
        get { lock.withLock { _receivedLongitude } }
        set { lock.withLock { _receivedLongitude = newValue } }
    }

    private(set) var cancellationCount: Int {
        get { lock.withLock { _cancellationCount } }
        set { lock.withLock { _cancellationCount = newValue } }
    }

    // MARK: - Configuration

    var result: Result<CurrentWeather, Error> {
        get { lock.withLock { _result } }
        set { lock.withLock { _result = newValue } }
    }

    var shouldSuspend: Bool {
        get { lock.withLock { _shouldSuspend } }
        set { lock.withLock { _shouldSuspend = newValue } }
    }

    // MARK: - Private Properties

    private let lock = NSLock()
    private var _fetchCallCount = 0
    private var _receivedLatitude: Double?
    private var _receivedLongitude: Double?
    private var _cancellationCount = 0
    private var _result: Result<CurrentWeather, Error>
    private var _shouldSuspend = false

    // MARK: - Initialization

    init(
        result: Result<CurrentWeather, Error> = .failure(
            NetworkError.invalidResponse
        )
    ) {
        _result = result
    }

    // MARK: - WeatherFetching

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double
    ) async throws -> CurrentWeather {
        let invocation = lock.withLock {
            _fetchCallCount += 1
            _receivedLatitude = latitude
            _receivedLongitude = longitude
            return (_result, _shouldSuspend)
        }

        if invocation.1 {
            await suspendUntilResumedOrCancelled()
            try Task.checkCancellation()
        }

        return try invocation.0.get()
    }

    // MARK: - Private Methods

    private func suspendUntilResumedOrCancelled() async {
        let stream = AsyncStream<Void> { continuation in
            continuation.onTermination = { [weak self] termination in
                guard case .cancelled = termination else {
                    return
                }

                self?.lock.withLock {
                    self?._cancellationCount += 1
                }
            }
        }

        for await _ in stream {}
    }
}
