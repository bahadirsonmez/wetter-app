import UIKit

struct TemperatureGraphLayoutMetrics: Equatable {

    let itemSize: CGSize
    let itemSpacing: CGFloat
    let sectionSpacing: CGFloat
    let headerHeight: CGFloat
    let headerSpacing: CGFloat
    let contentInsets: UIEdgeInsets

    init(
        itemSize: CGSize = CGSize(width: 80, height: 144),
        itemSpacing: CGFloat = 8,
        sectionSpacing: CGFloat = 24,
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
}
