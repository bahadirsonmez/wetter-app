import UIKit
import WeatherViewModel

final class WeatherTilesView: UIView {

    // MARK: - Properties

    private let layout: WeatherTilesLayout
    private var tiles: [WeatherTileViewData] = []
    private var tileViews: [WeatherTileView] = []

    var onMinimumRequiredHeightChange: (() -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        layout = WeatherTilesLayout()
        super.init(frame: frame)
    }

    init(
        frame: CGRect = .zero,
        layout: WeatherTilesLayout
    ) {
        self.layout = layout
        super.init(frame: frame)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    override func layoutSubviews() {
        super.layoutSubviews()

        let result = layout.makeLayout(
            availableSize: bounds.size,
            items: tileViews.prefix(tiles.count).map {
                $0.makeLayoutItem()
            }
        )

        apply(result)
    }

    override func traitCollectionDidChange(
        _ previousTraitCollection: UITraitCollection?
    ) {
        super.traitCollectionDidChange(previousTraitCollection)

        guard traitCollection.preferredContentSizeCategory
            != previousTraitCollection?.preferredContentSizeCategory else {
            return
        }

        setNeedsLayout()
        onMinimumRequiredHeightChange?()
    }

    // MARK: - Configuration

    func configure(with tiles: [WeatherTileViewData]) {
        guard self.tiles != tiles else {
            return
        }

        self.tiles = tiles
        ensureTileViewCapacity(tiles.count)

        for (index, tileView) in tileViews.enumerated() {
            guard tiles.indices.contains(index) else {
                tileView.reset()
                tileView.isHidden = true
                continue
            }

            tileView.configure(with: tiles[index])
        }

        setNeedsLayout()
        onMinimumRequiredHeightChange?()
    }

    func reset() {
        guard !tiles.isEmpty else {
            return
        }

        tiles = []
        tileViews.forEach {
            $0.reset()
            $0.isHidden = true
            $0.frame = .zero
        }
        setNeedsLayout()
        onMinimumRequiredHeightChange?()
    }

    func minimumRequiredHeight(
        for width: CGFloat,
        contentSizeCategory: UIContentSizeCategory
    ) -> CGFloat {
        guard !tiles.isEmpty else {
            return .zero
        }

        let items = tileViews.prefix(tiles.count).map {
            $0.makeLayoutItem(
                contentSizeCategory: contentSizeCategory
            )
        }

        return layout.minimumRequiredHeight(
            for: width,
            items: items
        )
    }

    func invalidateLayoutForBoundsChange() {
        setNeedsLayout()
        onMinimumRequiredHeightChange?()
    }
}

// MARK: - View Management

private extension WeatherTilesView {

    func ensureTileViewCapacity(_ requiredCount: Int) {
        guard requiredCount > tileViews.count else {
            return
        }

        for _ in tileViews.count..<requiredCount {
            let tileView = WeatherTileView()
            tileViews.append(tileView)
            addSubview(tileView)
        }
    }

    func apply(_ result: WeatherTilesLayoutResult) {
        for (index, tileView) in tileViews.enumerated() {
            guard
                index < result.visibleItemCount,
                result.itemFrames.indices.contains(index)
            else {
                tileView.isHidden = true
                tileView.frame = .zero
                continue
            }

            tileView.isHidden = false
            tileView.frame = result.itemFrames[index]
        }
    }

}
