import UIKit

final class LocationWeatherTilesContainerView: UIView {

    // MARK: - Subviews

    let tilesView = WeatherTilesView()

    // MARK: - Properties

    private var contentHeight: CGFloat = .zero

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(tilesView)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Sizing

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: contentHeight
        )
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        tilesView.frame = bounds
        tilesView.layoutIfNeeded()

        let newContentHeight = tilesView.intrinsicContentSize.height
        guard contentHeight != newContentHeight else {
            return
        }

        contentHeight = newContentHeight
        invalidateIntrinsicContentSize()
    }
}
