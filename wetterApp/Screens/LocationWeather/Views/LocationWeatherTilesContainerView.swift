import UIKit

final class LocationWeatherTilesContainerView: UIView {

    // MARK: - Subviews

    let tilesView = WeatherTilesView()

    // MARK: - Properties

    private var lastLayoutWidth: CGFloat = .zero

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setContentCompressionResistancePriority(
            UILayoutPriority(751),
            for: .vertical
        )
        addSubview(tilesView)
        tilesView.onMinimumRequiredHeightChange = { [weak self] in
            self?.invalidateIntrinsicContentSize()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override var intrinsicContentSize: CGSize {
        CGSize(
            width: UIView.noIntrinsicMetric,
            height: tilesView.minimumRequiredHeight(
                for: bounds.width,
                contentSizeCategory:
                    traitCollection.preferredContentSizeCategory
            )
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        if bounds.width != lastLayoutWidth {
            lastLayoutWidth = bounds.width
            invalidateIntrinsicContentSize()
        }

        tilesView.frame = bounds
        tilesView.layoutIfNeeded()
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.preferredContentSizeCategory
            != previousTraitCollection?.preferredContentSizeCategory else {
            return
        }

        invalidateIntrinsicContentSize()
    }
}
