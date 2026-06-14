import UIKit
import WeatherViewModel

final class LocationSearchResultCell: UITableViewCell {

    static let reuseIdentifier = "LocationSearchResultCell"

    override init(
        style: UITableViewCell.CellStyle,
        reuseIdentifier: String?
    ) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        textLabel?.adjustsFontForContentSizeCategory = true
        detailTextLabel?.adjustsFontForContentSizeCategory = true
        accessoryType = .none
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(with viewData: LocationSearchResultViewData) {
        textLabel?.text = viewData.title
        detailTextLabel?.text = viewData.subtitle
        detailTextLabel?.isHidden = viewData.subtitle == nil
    }
}
