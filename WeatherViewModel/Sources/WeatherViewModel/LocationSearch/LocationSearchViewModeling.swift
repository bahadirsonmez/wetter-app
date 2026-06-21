/// Drives debounced location search and saving for the search screen.
@MainActor
public protocol LocationSearchViewModeling: AnyObject {

    var state: LocationSearchViewState { get }
    var onStateChange: ((LocationSearchViewState) -> Void)? { get set }
    var onLocationAdded: (() -> Void)? { get set }

    /// Starts a debounced search for the provided query text.
    func search(query: String)

    /// Saves the currently loaded result at the given index.
    func selectResult(at index: Int)
}
