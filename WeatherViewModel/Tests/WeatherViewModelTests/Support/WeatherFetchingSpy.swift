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

    var ignoresCancellation: Bool {
        get { lock.withLock { _ignoresCancellation } }
        set { lock.withLock { _ignoresCancellation = newValue } }
    }

    // MARK: - Private Properties

    private let lock = NSLock()
    private var _fetchCallCount = 0
    private var _receivedLatitude: Double?
    private var _receivedLongitude: Double?
    private var _cancellationCount = 0
    private var _result: Result<CurrentWeather, Error>
    private var _shouldSuspend = false
    private var _ignoresCancellation = false
    private var pendingRequests: [
        Int: CheckedContinuation<CurrentWeather, Error>
    ] = [:]
    private var pendingResults: [Int: Result<CurrentWeather, Error>] = [:]
    private var cancelledRequests: Set<Int> = []

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
            return (
                requestNumber: _fetchCallCount,
                result: _result,
                shouldSuspend: _shouldSuspend,
                ignoresCancellation: _ignoresCancellation
            )
        }

        guard invocation.shouldSuspend else {
            return try invocation.result.get()
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let immediateResult: Result<CurrentWeather, Error>? =
                    lock.withLock {
                    if let result = pendingResults.removeValue(
                        forKey: invocation.requestNumber
                    ) {
                        return result
                    }

                    if cancelledRequests.remove(
                        invocation.requestNumber
                    ) != nil {
                        return Result.failure(CancellationError())
                    }

                    pendingRequests[invocation.requestNumber] = continuation
                    return nil
                }

                if let immediateResult {
                    continuation.resume(with: immediateResult)
                }
            }
        } onCancel: {
            let continuation: CheckedContinuation<CurrentWeather, Error>? =
                lock.withLock {
                _cancellationCount += 1

                guard !invocation.ignoresCancellation else {
                    return nil
                }

                guard let continuation = pendingRequests.removeValue(
                    forKey: invocation.requestNumber
                ) else {
                    cancelledRequests.insert(invocation.requestNumber)
                    return nil
                }

                return continuation
            }

            continuation?.resume(throwing: CancellationError())
        }
    }

    func fetchForecast(
        latitude: Double,
        longitude: Double
    ) async throws -> ForecastResponse {
        throw NetworkError.invalidResponse
    }

    // MARK: - Test Control

    func completeRequest(
        _ requestNumber: Int,
        with result: Result<CurrentWeather, Error>
    ) {
        let continuation: CheckedContinuation<CurrentWeather, Error>? =
            lock.withLock {
            guard let continuation = pendingRequests.removeValue(
                forKey: requestNumber
            ) else {
                pendingResults[requestNumber] = result
                return nil
            }

            return continuation
        }

        continuation?.resume(with: result)
    }
}
