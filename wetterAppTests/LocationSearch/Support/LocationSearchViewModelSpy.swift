import WeatherViewModel

@MainActor
final class LocationSearchViewModelSpy: LocationSearchViewModeling {

    var state: LocationSearchViewState = .idle
    var onStateChange: ((LocationSearchViewState) -> Void)?
    var onLocationAdded: (() -> Void)?

    private(set) var receivedQueries: [String] = []
    private(set) var selectedIndexes: [Int] = []

    func search(query: String) {
        receivedQueries.append(query)
    }

    func selectResult(at index: Int) {
        selectedIndexes.append(index)
    }

    func send(_ state: LocationSearchViewState) {
        self.state = state
        onStateChange?(state)
    }

    func sendLocationAdded() {
        onLocationAdded?()
    }
}
