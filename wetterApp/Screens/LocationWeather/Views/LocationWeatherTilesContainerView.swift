import UIKit

final class LocationWeatherTilesContainerView: UIView {

    // MARK: - Subviews

    let tilesView = WeatherTilesView()

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tilesView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        tilesView.frame = bounds
        tilesView.layoutIfNeeded()
    }
}
