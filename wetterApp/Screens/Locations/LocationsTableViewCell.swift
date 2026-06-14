import UIKit
import WeatherViewModel

final class LocationsTableViewCell: UITableViewCell {

    static let reuseIdentifier = "LocationsTableViewCell"

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.adjustsFontForContentSizeCategory = true
        detailTextLabel?.adjustsFontForContentSizeCategory = true
        accessoryType = .disclosureIndicator
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewData: LocationsListItemViewData) {
        textLabel?.text = viewData.title
        detailTextLabel?.text = viewData.subtitle
        detailTextLabel?.isHidden = viewData.subtitle == nil
    }
}
