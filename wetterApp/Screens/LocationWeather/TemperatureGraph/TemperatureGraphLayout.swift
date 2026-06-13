import UIKit

final class TemperatureGraphLayout: UICollectionViewLayout {

    static let sectionHeaderKind = UICollectionView
        .elementKindSectionHeader

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

    init(metrics: TemperatureGraphLayoutMetrics = .init()) {
        self.metrics = metrics
        super.init()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepare() {
        super.prepare()

        guard let collectionView else {
            reset()
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
                forSupplementaryViewOfKind: Self.sectionHeaderKind,
                with: headerIndexPath
            )
            header.frame = geometry.sections[sectionIndex].headerFrame
            header.zIndex = 1
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
    }

    override var collectionViewContentSize: CGSize {
        contentSize
    }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        // UICollectionView asks only for elements near its visible bounds, so
        // avoid returning cached attributes outside the requested rectangle.
        let items = itemAttributes.values.filter {
            $0.frame.intersects(rect)
        }
        let headers = headerAttributes.values.filter {
            $0.frame.intersects(rect)
        }

        return Array(items) + Array(headers)
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        // Direct lookup is used when UICollectionView requests a single cell.
        itemAttributes[indexPath]
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        guard elementKind == Self.sectionHeaderKind else {
            return nil
        }

        // Each section owns one reusable day header.
        return headerAttributes[indexPath]
    }

    override func shouldInvalidateLayout(
        forBoundsChange newBounds: CGRect
    ) -> Bool {
        guard let collectionView else {
            return false
        }

        // Recalculate when scrolling or when rotation changes the viewport.
        return collectionView.bounds != newBounds
    }
}

// MARK: - Helpers

private extension TemperatureGraphLayout {

    func reset() {
        itemAttributes.removeAll(keepingCapacity: true)
        headerAttributes.removeAll(keepingCapacity: true)
        contentSize = .zero
    }
}
