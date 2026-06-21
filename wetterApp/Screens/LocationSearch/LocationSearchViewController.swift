import UIKit
import WeatherViewModel

final class LocationSearchViewController: UITableViewController {

    // MARK: - Properties

    private let viewModel: any LocationSearchViewModeling
    private let searchController = UISearchController(
        searchResultsController: nil
    )

    var onLocationAdded: (() -> Void)?

    // MARK: - Initialization

    init(viewModel: any LocationSearchViewModeling) {
        self.viewModel = viewModel
        super.init(style: .plain)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()
        configureNavigation()
        configureTableView()
        configureSearchController()
        bindViewModel()
        render(viewModel.state)
    }

    // MARK: - Table View Data Source

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        loadedItems.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            loadedItems.indices.contains(indexPath.row),
            let cell = tableView.dequeueReusableCell(
                withIdentifier: LocationSearchResultCell.reuseIdentifier,
                for: indexPath
            ) as? LocationSearchResultCell
        else {
            return UITableViewCell()
        }

        cell.configure(with: loadedItems[indexPath.row])
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        viewModel.selectResult(at: indexPath.row)
    }

    // MARK: - Setup

    private func configureNavigation() {
        title = "Add Location"
    }

    private func configureTableView() {
        tableView.register(
            LocationSearchResultCell.self,
            forCellReuseIdentifier: LocationSearchResultCell.reuseIdentifier
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.keyboardDismissMode = .onDrag
    }

    private func configureSearchController() {
        searchController.searchResultsUpdater = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search cities"
        navigationItem.searchController = searchController
        navigationItem.hidesSearchBarWhenScrolling = false
        definesPresentationContext = true
    }

    private func bindViewModel() {
        viewModel.onStateChange = { [weak self] state in
            self?.render(state)
        }
        viewModel.onLocationAdded = { [weak self] in
            self?.onLocationAdded?()
        }
    }

    // MARK: - Rendering

    private var loadedItems: [LocationSearchResultViewData] {
        guard case let .loaded(items) = viewModel.state else {
            return []
        }
        return items
    }

    private func render(_ state: LocationSearchViewState) {
        switch state {
        case .idle:
            tableView.backgroundView = makeMessageLabel(
                text: "Search for a city to add a location."
            )
        case .loading:
            let activityIndicator = UIActivityIndicatorView(style: .medium)
            activityIndicator.startAnimating()
            tableView.backgroundView = activityIndicator
        case .loaded:
            tableView.backgroundView = nil
        case .empty:
            tableView.backgroundView = makeMessageLabel(
                text: "No locations found."
            )
        case let .failed(error):
            tableView.backgroundView = makeMessageLabel(text: error.message)
        }

        tableView.reloadData()
    }

    private func makeMessageLabel(text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.font = .preferredFont(forTextStyle: .body)
        label.adjustsFontForContentSizeCategory = true
        label.numberOfLines = 0
        return label
    }
}

// MARK: - UISearchResultsUpdating

extension LocationSearchViewController: UISearchResultsUpdating {

    func updateSearchResults(for searchController: UISearchController) {
        viewModel.search(query: searchController.searchBar.text ?? "")
    }
}
