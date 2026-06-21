import UIKit

final class TemperatureGraphLayout: UICollectionViewLayout {

    // MARK: - Properties

    private static let headerZIndex = 1_000

    override class var invalidationContextClass: AnyClass {
        TemperatureGraphLayoutInvalidationContext.self
    }

    var metrics: TemperatureGraphLayoutMetrics {
        didSet {
            invalidateLayout()
        }
    }

    private var itemAttributes: [
        IndexPath: UICollectionViewLayoutAttributes
    ] = [:]
    private var headerAttributes: [
        IndexPath: UICollectionViewLayoutAttributes
    ] = [:]
    private var contentSize: CGSize = .zero
    private var needsGeometryRebuild = true

    // MARK: - Initialization

    init(metrics: TemperatureGraphLayoutMetrics = .init()) {
        self.metrics = metrics
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    // Builds and caches layout attributes from the testable geometry output.
    override func prepare() {
        super.prepare()

        guard let collectionView else {
            reset()
            return
        }
        guard needsGeometryRebuild else {
            return
        }

        let sectionItemCounts = (0..<collectionView.numberOfSections).map {
            collectionView.numberOfItems(inSection: $0)
        }
        let geometry = TemperatureGraphLayoutGeometry(
            sectionItemCounts: sectionItemCounts,
            containerSize: collectionView.bounds.size,
            metrics: metrics
        )

        // Convert the testable CGRect output into UIKit layout attributes and
        // cache them for the collection view's subsequent queries.
        reset()
        contentSize = geometry.contentSize

        for sectionIndex in geometry.sections.indices {
            let headerIndexPath = IndexPath(
                item: .zero,
                section: sectionIndex
            )
            let header = UICollectionViewLayoutAttributes(
                forSupplementaryViewOfKind:
                    ForecastDayHeaderView.elementKind,
                with: headerIndexPath
            )
            header.frame = geometry.sections[sectionIndex].headerFrame
            header.zIndex = Self.headerZIndex
            headerAttributes[headerIndexPath] = header

            for itemIndex in geometry.sections[sectionIndex]
                .itemFrames.indices {
                let indexPath = IndexPath(
                    item: itemIndex,
                    section: sectionIndex
                )
                let item = UICollectionViewLayoutAttributes(
                    forCellWith: indexPath
                )
                item.frame = geometry.sections[sectionIndex]
                    .itemFrames[itemIndex]
                itemAttributes[indexPath] = item
            }
        }

        needsGeometryRebuild = false
    }

    override var collectionViewContentSize: CGSize {
        contentSize
    }

    // Returns only visible cells and sticky headers for the requested rect.
    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        // UICollectionView asks only for elements near its visible bounds, so
        // avoid returning cached attributes outside the requested rectangle.
        let items = itemAttributes.values.filter {
            $0.frame.intersects(rect)
        }
        let headers = headerAttributes.keys.compactMap {
            stickyHeaderAttributes(at: $0)
        }.filter {
            $0.frame.intersects(rect)
        }

        return Array(items) + Array(headers)
    }

    // Returns the cached attributes for a single forecast cell.
    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        // Direct lookup is used when UICollectionView requests a single cell.
        itemAttributes[indexPath]
    }

    // Returns the sticky attributes for a section day header.
    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard elementKind == ForecastDayHeaderView.elementKind else {
            return nil
        }

        // Each section owns one reusable day header.
        return stickyHeaderAttributes(at: indexPath)
    }

    // Invalidates on scroll and resize so sticky headers stay in sync.
    override func shouldInvalidateLayout(
        forBoundsChange newBounds: CGRect
    ) -> Bool {
        guard let collectionView else {
            return false
        }

        // Scrolling updates sticky headers, while size changes additionally
        // rebuild the cached graph geometry.
        return collectionView.bounds != newBounds
    }

    // Marks whether the bounds change needs full geometry or header-only work.
    override func invalidationContext(
        forBoundsChange newBounds: CGRect
    ) -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(
            forBoundsChange: newBounds
        )
        guard
            let context = context
                as? TemperatureGraphLayoutInvalidationContext,
            let collectionView
        else {
            return context
        }

        if collectionView.bounds.size != newBounds.size {
            context.invalidatesGeometry = true
        } else if collectionView.bounds.origin != newBounds.origin {
            context.invalidatesStickyHeadersOnly = true
            context.invalidateSupplementaryElements(
                ofKind: ForecastDayHeaderView.elementKind,
                at: Array(headerAttributes.keys)
            )
        }

        return context
    }

    // Updates the geometry rebuild flag before UIKit runs the invalidation.
    override func invalidateLayout(
        with context: UICollectionViewLayoutInvalidationContext
    ) {
        if let context = context
            as? TemperatureGraphLayoutInvalidationContext {
            if context.invalidatesGeometry
                || context.invalidateEverything
                || context.invalidateDataSourceCounts {
                needsGeometryRebuild = true
            }
        } else {
            needsGeometryRebuild = true
        }

        super.invalidateLayout(with: context)
    }
}

// MARK: - Helpers

private extension TemperatureGraphLayout {

    // Clears cached attributes before rebuilding geometry.
    func reset() {
        itemAttributes.removeAll(keepingCapacity: true)
        headerAttributes.removeAll(keepingCapacity: true)
        contentSize = .zero
        needsGeometryRebuild = true
    }

    // Copies cached header attributes and adjusts them for horizontal stickiness.
    func stickyHeaderAttributes(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard
            let collectionView,
            let cachedAttributes = headerAttributes[indexPath],
            let attributes = cachedAttributes.copy()
                as? UICollectionViewLayoutAttributes
        else {
            return nil
        }

        let nextIndexPath = IndexPath(
            item: .zero,
            section: indexPath.section + 1
        )
        attributes.frame = TemperatureGraphLayoutGeometry.stickyHeaderFrame(
            cachedAttributes.frame,
            nextHeaderFrame: headerAttributes[nextIndexPath]?.frame,
            visibleLeftEdge: collectionView.bounds.minX
        )
        return attributes
    }
}
