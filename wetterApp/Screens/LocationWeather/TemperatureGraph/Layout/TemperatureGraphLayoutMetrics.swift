import UIKit

struct TemperatureGraphLayoutMetrics: Equatable {

    private static let graphHeight: CGFloat = 60
    private static let labelsToGraphSpacing: CGFloat = 8
    private static let labelSpacing: CGFloat = 2

    let itemSize: CGSize
    let itemSpacing: CGFloat
    let sectionSpacing: CGFloat
    let headerHeight: CGFloat
    let headerSpacing: CGFloat
    let contentInsets: UIEdgeInsets

    var contentHeight: CGFloat {
        contentInsets.top
            + headerHeight
            + headerSpacing
            + itemSize.height
            + contentInsets.bottom
    }

    init(
        itemSize: CGSize = CGSize(width: 80, height: 144),
        itemSpacing: CGFloat = -1,
        sectionSpacing: CGFloat = -1,
        headerHeight: CGFloat = 28,
        headerSpacing: CGFloat = 8,
        contentInsets: UIEdgeInsets = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        )
    ) {
        self.itemSize = itemSize
        self.itemSpacing = itemSpacing
        self.sectionSpacing = sectionSpacing
        self.headerHeight = headerHeight
        self.headerSpacing = headerSpacing
        self.contentInsets = contentInsets
    }

    func scaled(
        for contentSizeCategory: UIContentSizeCategory
    ) -> TemperatureGraphLayoutMetrics {
        let traits = UITraitCollection(
            preferredContentSizeCategory: contentSizeCategory
        )
        let timeFont = UIFont.preferredFont(
            forTextStyle: .caption1,
            compatibleWith: traits
        )
        let temperatureFont = UIFont.preferredFont(
            forTextStyle: .headline,
            compatibleWith: traits
        )
        let conditionFont = UIFont.preferredFont(
            forTextStyle: .caption2,
            compatibleWith: traits
        )
        let headerFont = UIFont.preferredFont(
            forTextStyle: .headline,
            compatibleWith: traits
        )
        let labelsHeight = ceil(timeFont.lineHeight)
            + ceil(temperatureFont.lineHeight)
            + ceil(conditionFont.lineHeight) * 2
            + Self.labelSpacing * 2
        let minimumItemHeight = labelsHeight
            + Self.labelsToGraphSpacing
            + Self.graphHeight

        return TemperatureGraphLayoutMetrics(
            itemSize: CGSize(
                width: itemSize.width,
                height: max(itemSize.height, ceil(minimumItemHeight))
            ),
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            headerHeight: max(
                headerHeight,
                ceil(headerFont.lineHeight)
            ),
            headerSpacing: headerSpacing,
            contentInsets: contentInsets
        )
    }

    func compactedVertically() -> TemperatureGraphLayoutMetrics {
        TemperatureGraphLayoutMetrics(
            itemSize: itemSize,
            itemSpacing: itemSpacing,
            sectionSpacing: sectionSpacing,
            headerHeight: headerHeight,
            headerSpacing: min(headerSpacing, 4),
            contentInsets: UIEdgeInsets(
                top: min(contentInsets.top, 8),
                left: contentInsets.left,
                bottom: min(contentInsets.bottom, 8),
                right: contentInsets.right
            )
        )
    }
}
