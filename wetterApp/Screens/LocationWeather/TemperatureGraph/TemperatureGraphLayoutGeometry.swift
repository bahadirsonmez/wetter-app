import UIKit

struct TemperatureGraphLayoutGeometry {

    struct Section: Equatable {
        let headerFrame: CGRect
        let itemFrames: [CGRect]
    }

    let sections: [Section]
    let contentSize: CGSize

    init(
        sectionItemCounts: [Int],
        containerSize: CGSize,
        metrics: TemperatureGraphLayoutMetrics
    ) {
        guard !sectionItemCounts.isEmpty else {
            sections = []
            contentSize = CGSize(
                width: max(.zero, containerSize.width),
                height: .zero
            )
            return
        }

        var currentX = metrics.contentInsets.left
        var sections: [Section] = []

        // Sections represent days and are placed next to each other
        // horizontally. Each header spans all forecast items for that day.
        for itemCount in sectionItemCounts {
            let count = max(.zero, itemCount)
            let sectionWidth = Self.sectionWidth(
                itemCount: count,
                metrics: metrics
            )
            let headerFrame = CGRect(
                x: currentX,
                y: metrics.contentInsets.top,
                width: sectionWidth,
                height: metrics.headerHeight
            )
            let itemY = headerFrame.maxY + metrics.headerSpacing
            let itemFrames = (0..<count).map { itemIndex in
                CGRect(
                    x: currentX + CGFloat(itemIndex)
                        * (metrics.itemSize.width + metrics.itemSpacing),
                    y: itemY,
                    width: metrics.itemSize.width,
                    height: metrics.itemSize.height
                )
            }

            sections.append(
                Section(
                    headerFrame: headerFrame,
                    itemFrames: itemFrames
                )
            )
            currentX += sectionWidth + metrics.sectionSpacing
        }

        // The final section has no trailing section spacing. Content width
        // still fills the collection view when the graph is narrower.
        currentX -= metrics.sectionSpacing
        let contentWidth = currentX + metrics.contentInsets.right
        let contentHeight = metrics.contentInsets.top
            + metrics.headerHeight
            + metrics.headerSpacing
            + metrics.itemSize.height
            + metrics.contentInsets.bottom

        self.sections = sections
        contentSize = CGSize(
            width: max(containerSize.width, contentWidth),
            height: contentHeight
        )
    }

    func itemFrame(at indexPath: IndexPath) -> CGRect? {
        guard
            sections.indices.contains(indexPath.section),
            sections[indexPath.section].itemFrames.indices.contains(
                indexPath.item
            )
        else {
            return nil
        }

        return sections[indexPath.section].itemFrames[indexPath.item]
    }

    func headerFrame(in section: Int) -> CGRect? {
        guard sections.indices.contains(section) else {
            return nil
        }

        return sections[section].headerFrame
    }

    static func stickyHeaderFrame(
        _ headerFrame: CGRect,
        nextHeaderFrame: CGRect?,
        visibleLeftEdge: CGFloat
    ) -> CGRect {
        let stickyX = max(headerFrame.minX, visibleLeftEdge)
        let maximumX = nextHeaderFrame.map {
            $0.minX - headerFrame.width
        } ?? stickyX

        var frame = headerFrame
        // Clamp the header to its section start and let the next day push it
        // left before the two headers can overlap.
        frame.origin.x = min(stickyX, maximumX)
        return frame
    }
}

// MARK: - Helpers

private extension TemperatureGraphLayoutGeometry {

    static func sectionWidth(
        itemCount: Int,
        metrics: TemperatureGraphLayoutMetrics
    ) -> CGFloat {
        guard itemCount > 0 else {
            return metrics.itemSize.width
        }

        // N items contain N item widths and N - 1 spaces between them.
        return CGFloat(itemCount) * metrics.itemSize.width
            + CGFloat(itemCount - 1) * metrics.itemSpacing
    }
}
