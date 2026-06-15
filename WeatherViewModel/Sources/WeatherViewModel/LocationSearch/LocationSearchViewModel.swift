import Foundation
import WeatherModel

@MainActor
public final class LocationSearchViewModel: LocationSearchViewModeling {

    // MARK: - Public Properties

    public private(set) var state: LocationSearchViewState = .idle
    public var onStateChange: ((LocationSearchViewState) -> Void)?
    public var onLocationAdded: (() -> Void)?

    // MARK: - Private Properties

    private let searchService: any LocationSearching
    private let store: any LocationsStoring
    private let debounceNanoseconds: UInt64
    private let idGenerator: () -> UUID
    private var currentTask: Task<Void, Never>?
    private var searchResults: [LocationSearchResult] = []
    private var searchGeneration = 0

    // MARK: - Initialization

    public convenience init(
        searchService: any LocationSearching,
        store: any LocationsStoring
    ) {
        self.init(
            searchService: searchService,
            store: store,
            debounceNanoseconds: 350_000_000,
            idGenerator: UUID.init
        )
    }

    init(
        searchService: any LocationSearching,
        store: any LocationsStoring,
        debounceNanoseconds: UInt64,
        idGenerator: @escaping () -> UUID
    ) {
        self.searchService = searchService
        self.store = store
        self.debounceNanoseconds = debounceNanoseconds
        self.idGenerator = idGenerator
    }

    deinit {
        currentTask?.cancel()
    }

    // MARK: - Public Methods

    /// Performs a search for locations matching the given query.
    public func search(query: String) {
        currentTask?.cancel()
        searchGeneration += 1
        let generation = searchGeneration
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)

        guard trimmedQuery.count >= 2 else {
            searchResults = []
            updateState(.idle)
            return
        }

        updateState(.loading)
        let service = searchService
        let debounceNanoseconds = debounceNanoseconds

        currentTask = Task { [weak self] in
            do {
                try await Task.sleep(nanoseconds: debounceNanoseconds)
                let results = try await service.search(query: trimmedQuery)

                guard
                    !Task.isCancelled,
                    let self,
                    generation == searchGeneration
                else {
                    return
                }

                searchResults = results
                updateState(
                    results.isEmpty
                        ? .empty
                        : .loaded(results.map(makeViewData))
                )
            } catch is CancellationError {
                return
            } catch {
                guard
                    !Task.isCancelled,
                    let self,
                    generation == searchGeneration
                else {
                    return
                }

                searchResults = []
                updateState(.failed(makeViewError(from: error)))
            }
        }
    }

    /// Selects a search result at the specified index and saves it to the store.
    public func selectResult(at index: Int) {
        guard searchResults.indices.contains(index) else {
            return
        }

        let result = searchResults[index]
        let snapshot = store.loadSnapshot()

        guard !snapshot.locations.contains(where: {
            distance(
                latitude: result.latitude,
                longitude: result.longitude,
                toLatitude: $0.latitude,
                longitude: $0.longitude
            ) <= 100
        }) else {
            return
        }

        let location = SavedLocation(
            id: idGenerator(),
            name: result.name,
            state: result.state,
            countryCode: result.countryCode,
            latitude: result.latitude,
            longitude: result.longitude
        )
        let updatedSnapshot = SavedLocationsSnapshot(
            locations: snapshot.locations + [location],
            lastViewedLocationID: snapshot.lastViewedLocationID
        )

        do {
            try store.saveSnapshot(updatedSnapshot)
            onLocationAdded?()
        } catch {
            updateState(.failed(.persistenceFailed))
        }
    }

    // MARK: - Private Methods

    private func updateState(_ newState: LocationSearchViewState) {
        state = newState
        onStateChange?(newState)
    }

    private func makeViewData(
        for result: LocationSearchResult
    ) -> LocationSearchResultViewData {
        let subtitle = [result.state, result.countryCode]
            .compactMap { value -> String? in
                guard let value, !value.isEmpty else {
                    return nil
                }
                return value
            }
            .joined(separator: ", ")

        return LocationSearchResultViewData(
            title: result.name,
            subtitle: subtitle.isEmpty ? nil : subtitle
        )
    }

    private func makeViewError(from error: Error) -> LocationSearchViewError {
        if error is LocationSearchError {
            return .unavailable
        }
        return .unknown
    }

    private func distance(
        latitude: Double,
        longitude: Double,
        toLatitude otherLatitude: Double,
        longitude otherLongitude: Double
    ) -> Double {
        let earthRadius = 6_371_000.0
        let latitudeDelta = (otherLatitude - latitude) * .pi / 180
        let longitudeDelta = (otherLongitude - longitude) * .pi / 180
        let startLatitude = latitude * .pi / 180
        let endLatitude = otherLatitude * .pi / 180
        let value = sin(latitudeDelta / 2) * sin(latitudeDelta / 2)
            + cos(startLatitude) * cos(endLatitude)
            * sin(longitudeDelta / 2) * sin(longitudeDelta / 2)

        return earthRadius * 2 * atan2(sqrt(value), sqrt(1 - value))
    }
}
