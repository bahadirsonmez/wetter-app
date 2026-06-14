@MainActor
public protocol LocationSearchViewModeling: AnyObject {

    var state: LocationSearchViewState { get }
    var onStateChange: ((LocationSearchViewState) -> Void)? { get set }
    var onLocationAdded: (() -> Void)? { get set }

    func search(query: String)
    func selectResult(at index: Int)
}
