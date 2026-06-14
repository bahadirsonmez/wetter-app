import UIKit
import WeatherViewModel

final class LocationsViewController: UITableViewController {

    // MARK: - Properties

    private let viewModel: any LocationsViewModeling

    var onAddLocation: (() -> Void)?

    // MARK: - Initialization

    init(viewModel: any LocationsViewModeling) {
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
        bindViewModel()
        viewModel.loadLocations()
    }

    // MARK: - Table View Data Source

    override func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        viewModel.items.count
    }

    override func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {
        guard
            viewModel.items.indices.contains(indexPath.row),
            let cell = tableView.dequeueReusableCell(
                withIdentifier: LocationsTableViewCell.reuseIdentifier,
                for: indexPath
            ) as? LocationsTableViewCell
        else {
            return UITableViewCell()
        }

        cell.configure(with: viewModel.items[indexPath.row])
        return cell
    }

    override func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {
        tableView.deselectRow(at: indexPath, animated: true)
        guard viewModel.items.indices.contains(indexPath.row) else {
            return
        }

        viewModel.selectLocation(
            id: viewModel.items[indexPath.row].identifier
        )
    }

    // MARK: - Editing

    override func tableView(
        _ tableView: UITableView,
        canEditRowAt indexPath: IndexPath
    ) -> Bool {
        viewModel.items.indices.contains(indexPath.row)
            && viewModel.items[indexPath.row].isDeletable
    }

    override func tableView(
        _ tableView: UITableView,
        commit editingStyle: UITableViewCell.EditingStyle,
        forRowAt indexPath: IndexPath
    ) {
        guard
            editingStyle == .delete,
            viewModel.items.indices.contains(indexPath.row),
            case let .saved(id) = viewModel.items[indexPath.row].identifier
        else {
            return
        }

        viewModel.deleteLocation(id: id)
    }

    override func tableView(
        _ tableView: UITableView,
        canMoveRowAt indexPath: IndexPath
    ) -> Bool {
        viewModel.items.indices.contains(indexPath.row)
            && viewModel.items[indexPath.row].isMovable
    }

    override func tableView(
        _ tableView: UITableView,
        moveRowAt sourceIndexPath: IndexPath,
        to destinationIndexPath: IndexPath
    ) {
        guard sourceIndexPath.row > .zero else {
            return
        }

        let destinationRow = max(1, destinationIndexPath.row)
        viewModel.moveLocation(
            fromSavedIndex: sourceIndexPath.row - 1,
            toSavedIndex: destinationRow - 1
        )
    }

    override func tableView(
        _ tableView: UITableView,
        targetIndexPathForMoveFromRowAt sourceIndexPath: IndexPath,
        toProposedIndexPath proposedDestinationIndexPath: IndexPath
    ) -> IndexPath {
        guard proposedDestinationIndexPath.row > .zero else {
            return IndexPath(row: 1, section: proposedDestinationIndexPath.section)
        }

        return proposedDestinationIndexPath
    }

    // MARK: - Setup

    private func configureNavigation() {
        title = "Locations"
        navigationItem.leftBarButtonItem = editButtonItem
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .add,
            target: self,
            action: #selector(addLocation)
        )
    }

    private func configureTableView() {
        tableView.register(
            LocationsTableViewCell.self,
            forCellReuseIdentifier: LocationsTableViewCell.reuseIdentifier
        )
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
    }

    private func bindViewModel() {
        viewModel.onItemsChange = { [weak self] _ in
            self?.tableView.reloadData()
        }
    }

    // MARK: - Actions

    @objc
    private func addLocation() {
        onAddLocation?()
    }
}
