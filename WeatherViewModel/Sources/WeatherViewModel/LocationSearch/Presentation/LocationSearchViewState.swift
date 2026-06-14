public enum LocationSearchViewState: Equatable, Sendable {

    case idle
    case loading
    case loaded([LocationSearchResultViewData])
    case empty
    case failed(LocationSearchViewError)
}
