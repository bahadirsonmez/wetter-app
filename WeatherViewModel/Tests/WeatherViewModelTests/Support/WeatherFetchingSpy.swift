import Foundation
import WeatherModel

final class WeatherFetchingSpy: WeatherFetching, @unchecked Sendable {

    // MARK: - Recorded Values

    var fetchCallCount: Int {
        lock.withLock { currentRequest.callCount }
    }

    var forecastFetchCallCount: Int {
        lock.withLock { forecastRequest.callCount }
    }

    var receivedLatitude: Double? {
        lock.withLock { currentRequest.receivedLatitude }
    }

    var receivedLongitude: Double? {
        lock.withLock { currentRequest.receivedLongitude }
    }

    var forecastReceivedLatitude: Double? {
        lock.withLock { forecastRequest.receivedLatitude }
    }

    var forecastReceivedLongitude: Double? {
        lock.withLock { forecastRequest.receivedLongitude }
    }

    var receivedForceRefreshValues: [Bool] {
        lock.withLock { currentRequest.receivedForceRefreshValues }
    }

    var forecastReceivedForceRefreshValues: [Bool] {
        lock.withLock { forecastRequest.receivedForceRefreshValues }
    }

    var cancellationCount: Int {
        lock.withLock { currentRequest.cancellationCount }
    }

    var forecastCancellationCount: Int {
        lock.withLock { forecastRequest.cancellationCount }
    }

    // MARK: - Configuration

    var result: Result<CurrentWeather, Error> {
        get { lock.withLock { currentRequest.result } }
        set { lock.withLock { currentRequest.result = newValue } }
    }

    var forecastResult: Result<ForecastResponse, Error> {
        get { lock.withLock { forecastRequest.result } }
        set { lock.withLock { forecastRequest.result = newValue } }
    }

    var shouldSuspend: Bool {
        get { lock.withLock { currentRequest.shouldSuspend } }
        set { lock.withLock { currentRequest.shouldSuspend = newValue } }
    }

    var forecastShouldSuspend: Bool {
        get { lock.withLock { forecastRequest.shouldSuspend } }
        set { lock.withLock { forecastRequest.shouldSuspend = newValue } }
    }

    var ignoresCancellation: Bool {
        get { lock.withLock { currentRequest.ignoresCancellation } }
        set { lock.withLock { currentRequest.ignoresCancellation = newValue } }
    }

    var forecastIgnoresCancellation: Bool {
        get { lock.withLock { forecastRequest.ignoresCancellation } }
        set {
            lock.withLock {
                forecastRequest.ignoresCancellation = newValue
            }
        }
    }

    // MARK: - Private Properties

    private let lock = NSLock()
    private var currentRequest: RequestState<CurrentWeather>
    private var forecastRequest: RequestState<ForecastResponse>

    // MARK: - Initialization

    init(
        result: Result<CurrentWeather, Error> = .failure(
            NetworkError.invalidResponse
        ),
        forecastResult: Result<ForecastResponse, Error> = .failure(
            NetworkError.invalidResponse
        )
    ) {
        currentRequest = RequestState(result: result)
        forecastRequest = RequestState(result: forecastResult)
    }

    // MARK: - WeatherFetching

    func fetchCurrentWeather(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> CurrentWeather {
        try await performRequest(
            latitude: latitude,
            longitude: longitude,
            forceRefresh: forceRefresh,
            state: \.currentRequest
        )
    }

    func fetchForecast(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool
    ) async throws -> ForecastResponse {
        try await performRequest(
            latitude: latitude,
            longitude: longitude,
            forceRefresh: forceRefresh,
            state: \.forecastRequest
        )
    }

    // MARK: - Test Control

    func completeRequest(
        _ requestNumber: Int,
        with result: Result<CurrentWeather, Error>
    ) {
        complete(
            requestNumber,
            with: result,
            state: \.currentRequest
        )
    }

    func completeForecastRequest(
        _ requestNumber: Int,
        with result: Result<ForecastResponse, Error>
    ) {
        complete(
            requestNumber,
            with: result,
            state: \.forecastRequest
        )
    }
}

// MARK: - Request Handling

private extension WeatherFetchingSpy {

    struct Invocation<Response> {
        let requestNumber: Int
        let result: Result<Response, Error>
        let shouldSuspend: Bool
        let ignoresCancellation: Bool
    }

    struct RequestState<Response> {
        var callCount = 0
        var receivedLatitude: Double?
        var receivedLongitude: Double?
        var receivedForceRefreshValues: [Bool] = []
        var cancellationCount = 0
        var result: Result<Response, Error>
        var shouldSuspend = false
        var ignoresCancellation = false
        var pendingRequests: [
            Int: CheckedContinuation<Response, Error>
        ] = [:]
        var pendingResults: [Int: Result<Response, Error>] = [:]
        var cancelledRequests: Set<Int> = []
    }

    func performRequest<Response>(
        latitude: Double,
        longitude: Double,
        forceRefresh: Bool,
        state keyPath: ReferenceWritableKeyPath<
            WeatherFetchingSpy,
            RequestState<Response>
        >
    ) async throws -> Response {
        let invocation = lock.withLock {
            self[keyPath: keyPath].callCount += 1
            self[keyPath: keyPath].receivedLatitude = latitude
            self[keyPath: keyPath].receivedLongitude = longitude
            self[keyPath: keyPath].receivedForceRefreshValues.append(
                forceRefresh
            )
            let state = self[keyPath: keyPath]

            return Invocation(
                requestNumber: state.callCount,
                result: state.result,
                shouldSuspend: state.shouldSuspend,
                ignoresCancellation: state.ignoresCancellation
            )
        }

        guard invocation.shouldSuspend else {
            return try invocation.result.get()
        }

        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let immediateResult: Result<Response, Error>? = lock.withLock {
                    if let result = self[keyPath: keyPath]
                        .pendingResults
                        .removeValue(forKey: invocation.requestNumber) {
                        return result
                    }

                    if self[keyPath: keyPath].cancelledRequests.remove(
                        invocation.requestNumber
                    ) != nil {
                        return .failure(CancellationError())
                    }

                    self[keyPath: keyPath].pendingRequests[
                        invocation.requestNumber
                    ] = continuation
                    return nil
                }

                if let immediateResult {
                    continuation.resume(with: immediateResult)
                }
            }
        } onCancel: {
            let continuation: CheckedContinuation<Response, Error>? =
                lock.withLock {
                    self[keyPath: keyPath].cancellationCount += 1

                    guard !invocation.ignoresCancellation else {
                        return nil
                    }

                    guard let continuation = self[keyPath: keyPath]
                        .pendingRequests
                        .removeValue(forKey: invocation.requestNumber) else {
                        self[keyPath: keyPath].cancelledRequests.insert(
                            invocation.requestNumber
                        )
                        return nil
                    }

                    return continuation
                }

            continuation?.resume(throwing: CancellationError())
        }
    }

    func complete<Response>(
        _ requestNumber: Int,
        with result: Result<Response, Error>,
        state keyPath: ReferenceWritableKeyPath<
            WeatherFetchingSpy,
            RequestState<Response>
        >
    ) {
        let continuation: CheckedContinuation<Response, Error>? =
            lock.withLock {
                guard let continuation = self[keyPath: keyPath]
                    .pendingRequests
                    .removeValue(forKey: requestNumber) else {
                    self[keyPath: keyPath].pendingResults[
                        requestNumber
                    ] = result
                    return nil
                }

                return continuation
            }

        continuation?.resume(with: result)
    }
}
