import UIKit
import WeatherViewModel

final class WeatherTilesView: UIView {

    // MARK: - Properties

    private let layout: WeatherTilesLayout
    private var tiles: [WeatherTileViewData] = []
    private var tileViews: [WeatherTileView] = []
    private var preferredOrder: [WeatherTileIdentifier] = []
    private var draggedTileIdentifier: WeatherTileIdentifier?
    private weak var draggedTileView: WeatherTileView?

    var onMinimumRequiredHeightChange: (() -> Void)?

    // MARK: - Initialization

    override init(frame: CGRect) {
        layout = WeatherTilesLayout()
        super.init(frame: frame)
        setupInteractions()
    }

    init(
        frame: CGRect = .zero,
        layout: WeatherTilesLayout
    ) {
        self.layout = layout
        super.init(frame: frame)
        setupInteractions()
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

        apply(result, animated: false)
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
        let orderedTiles = orderedTiles(from: tiles)
        guard self.tiles != orderedTiles else {
            return
        }

        self.tiles = orderedTiles
        ensureTileViewCapacity(orderedTiles.count)

        for (index, tileView) in tileViews.enumerated() {
            guard orderedTiles.indices.contains(index) else {
                tileView.reset()
                tileView.isHidden = true
                continue
            }

            tileView.configure(with: orderedTiles[index])
        }

        setNeedsLayout()
        onMinimumRequiredHeightChange?()
    }

    func reset() {
        guard !tiles.isEmpty else {
            return
        }

        restoreDraggedTileAppearance()
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

    func orderedTiles(
        from tiles: [WeatherTileViewData]
    ) -> [WeatherTileViewData] {
        let identifiers = Set(tiles.map(\.id))
        preferredOrder.removeAll { !identifiers.contains($0) }

        for identifier in tiles.map(\.id)
        where !preferredOrder.contains(identifier) {
            preferredOrder.append(identifier)
        }

        let tilesByIdentifier = Dictionary(
            uniqueKeysWithValues: tiles.map { ($0.id, $0) }
        )
        return preferredOrder.compactMap { tilesByIdentifier[$0] }
    }

    func moveTile(
        with identifier: WeatherTileIdentifier,
        toVisibleIndex destinationIndex: Int
    ) {
        let visibleCount = visibleTileViews.count
        guard
            let sourceIndex = tiles.firstIndex(where: { $0.id == identifier }),
            sourceIndex < visibleCount,
            destinationIndex >= .zero,
            destinationIndex < visibleCount,
            sourceIndex != destinationIndex
        else {
            return
        }

        let tile = tiles.remove(at: sourceIndex)
        let normalizedDestination = min(destinationIndex, tiles.count)
        tiles.insert(tile, at: normalizedDestination)
        preferredOrder = tiles.map(\.id)

        bindTileViews()
        let result = makeLayoutResult()
        apply(result, animated: true)
        announceMove(of: tile)
    }

    func acceptsDrop(isLocalSession: Bool) -> Bool {
        isLocalSession
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
            tileView.addInteraction(UIDragInteraction(delegate: self))
            tileViews.append(tileView)
            addSubview(tileView)
        }
    }

    func bindTileViews() {
        for (index, tileView) in tileViews.enumerated() {
            guard tiles.indices.contains(index) else {
                tileView.reset()
                tileView.isHidden = true
                continue
            }

            tileView.configure(with: tiles[index])
        }
    }

    func makeLayoutResult() -> WeatherTilesLayoutResult {
        layout.makeLayout(
            availableSize: bounds.size,
            items: tileViews.prefix(tiles.count).map {
                $0.makeLayoutItem()
            }
        )
    }

    func apply(
        _ result: WeatherTilesLayoutResult,
        animated: Bool
    ) {
        let visibleCount = result.visibleItemCount
        let changes = {
            for (index, tileView) in self.tileViews.enumerated() {
                guard
                    index < visibleCount,
                    result.itemFrames.indices.contains(index)
                else {
                    tileView.alpha = .zero
                    tileView.frame = .zero
                    continue
                }

                tileView.isHidden = false
                tileView.alpha = 1
                tileView.frame = result.itemFrames[index]
            }
        }

        updateAccessibilityActions(visibleCount: visibleCount)

        guard animated else {
            changes()
            hideInvisibleTileViews(visibleCount: visibleCount)
            return
        }

        UIView.animate(
            withDuration: 0.25,
            delay: .zero,
            options: [.curveEaseInOut, .beginFromCurrentState],
            animations: changes
        ) { _ in
            self.hideInvisibleTileViews(visibleCount: visibleCount)
        }
    }

    func hideInvisibleTileViews(visibleCount: Int) {
        for (index, tileView) in tileViews.enumerated() {
            if index >= visibleCount {
                tileView.isHidden = true
                tileView.alpha = 1
                tileView.frame = .zero
            }
        }
    }

    var visibleTileViews: [WeatherTileView] {
        tileViews.filter { !$0.isHidden }
    }

    func updateAccessibilityActions(visibleCount: Int) {
        for (index, tileView) in tileViews.enumerated() {
            guard index < visibleCount else {
                tileView.configureAccessibilityActions(
                    canMoveEarlier: false,
                    canMoveLater: false
                )
                continue
            }

            tileView.onMoveEarlier = { [weak self, weak tileView] in
                guard let self, let identifier = tileView?.identifier else {
                    return
                }
                self.moveTile(
                    with: identifier,
                    toVisibleIndex: max(.zero, index - 1)
                )
            }
            tileView.onMoveLater = { [weak self, weak tileView] in
                guard let self, let identifier = tileView?.identifier else {
                    return
                }
                self.moveTile(
                    with: identifier,
                    toVisibleIndex: min(visibleCount - 1, index + 1)
                )
            }
            tileView.configureAccessibilityActions(
                canMoveEarlier: index > .zero,
                canMoveLater: index < visibleCount - 1
            )
        }
    }

    func announceMove(of tile: WeatherTileViewData) {
        UIAccessibility.post(
            notification: .announcement,
            argument: "\(tile.title) moved"
        )
    }
}

// MARK: - Interactions

private extension WeatherTilesView {

    func setupInteractions() {
        addInteraction(UIDropInteraction(delegate: self))
    }

    func restoreDraggedTileAppearance() {
        draggedTileView?.alpha = 1
        draggedTileView?.transform = .identity
        draggedTileView = nil
        draggedTileIdentifier = nil
    }
}

// MARK: - UIDragInteractionDelegate

extension WeatherTilesView: UIDragInteractionDelegate {

    func dragInteraction(
        _ interaction: UIDragInteraction,
        itemsForBeginning session: any UIDragSession
    ) -> [UIDragItem] {
        guard
            let tileView = interaction.view as? WeatherTileView,
            tileView.superview === self,
            !tileView.isHidden,
            let identifier = tileView.identifier
        else {
            return []
        }

        let itemProvider = NSItemProvider(
            object: identifier.rawValue as NSString
        )
        let dragItem = UIDragItem(itemProvider: itemProvider)
        dragItem.localObject = identifier
        draggedTileIdentifier = identifier
        draggedTileView = tileView
        return [dragItem]
    }

    func dragInteraction(
        _ interaction: UIDragInteraction,
        sessionWillBegin session: any UIDragSession
    ) {
        draggedTileView?.alpha = 0.35
        draggedTileView?.transform = CGAffineTransform(
            scaleX: 1.04,
            y: 1.04
        )
    }

    func dragInteraction(
        _ interaction: UIDragInteraction,
        session: any UIDragSession,
        didEndWith operation: UIDropOperation
    ) {
        restoreDraggedTileAppearance()
    }

    func dragInteraction(
        _ interaction: UIDragInteraction,
        previewForLifting item: UIDragItem,
        session: any UIDragSession
    ) -> UITargetedDragPreview? {
        guard let tileView = interaction.view as? WeatherTileView else {
            return nil
        }

        let parameters = UIDragPreviewParameters()
        parameters.backgroundColor = .clear
        parameters.visiblePath = UIBezierPath(
            roundedRect: tileView.bounds,
            cornerRadius: tileView.layer.cornerRadius
        )
        let target = UIDragPreviewTarget(
            container: self,
            center: tileView.center,
            transform: CGAffineTransform(scaleX: 1.04, y: 1.04)
        )
        return UITargetedDragPreview(
            view: tileView,
            parameters: parameters,
            target: target
        )
    }
}

// MARK: - UIDropInteractionDelegate

extension WeatherTilesView: UIDropInteractionDelegate {

    func dropInteraction(
        _ interaction: UIDropInteraction,
        canHandle session: any UIDropSession
    ) -> Bool {
        acceptsDrop(isLocalSession: session.localDragSession != nil)
    }

    func dropInteraction(
        _ interaction: UIDropInteraction,
        sessionDidUpdate session: any UIDropSession
    ) -> UIDropProposal {
        guard dropInteraction(interaction, canHandle: session) else {
            return UIDropProposal(operation: .forbidden)
        }

        return UIDropProposal(operation: .move)
    }

    func dropInteraction(
        _ interaction: UIDropInteraction,
        performDrop session: any UIDropSession
    ) {
        guard
            dropInteraction(interaction, canHandle: session),
            let identifier = session.items.first?.localObject
                as? WeatherTileIdentifier,
            identifier == draggedTileIdentifier,
            let destinationIndex = WeatherTilesReorderGeometry.destinationIndex(
                for: session.location(in: self),
                visibleFrames: visibleTileViews.map(\.frame)
            )
        else {
            restoreDraggedTileAppearance()
            return
        }

        moveTile(
            with: identifier,
            toVisibleIndex: destinationIndex
        )
        restoreDraggedTileAppearance()
    }
}
