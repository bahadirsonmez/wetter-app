import UIKit

struct WeatherTilesLayout {

    // MARK: - Properties

    private let metrics: WeatherTilesLayoutMetrics

    // MARK: - Initialization

    init(metrics: WeatherTilesLayoutMetrics = WeatherTilesLayoutMetrics()) {
        self.metrics = metrics
    }

    // MARK: - Layout

    func makeLayout(
        availableSize: CGSize,
        items: [WeatherTilesLayoutItem]
    ) -> WeatherTilesLayoutResult {
        let size = CGSize(
            width: max(.zero, availableSize.width),
            height: max(.zero, availableSize.height)
        )
        let usableSize = usableSize(in: size)

        guard
            !items.isEmpty,
            usableSize.width > .zero,
            usableSize.height > .zero
        else {
            return WeatherTilesLayoutResult(
                itemFrames: [],
                contentSize: size,
                visibleItemCount: .zero
            )
        }

        let visibleLayout = longestVisibleLayout(
            items: items,
            usableSize: usableSize
        )
        guard !visibleLayout.rows.isEmpty else {
            return WeatherTilesLayoutResult(
                itemFrames: [],
                contentSize: size,
                visibleItemCount: .zero
            )
        }

        // Every visible row shares the available height equally. Minimum tile
        // heights were already validated while selecting the visible prefix.
        let rowHeight = (
            usableSize.height
                - CGFloat(visibleLayout.rows.count - 1)
                * metrics.verticalSpacing
        ) / CGFloat(visibleLayout.rows.count)
        let frames = makeFrames(
            rows: visibleLayout.rows,
            rowHeight: rowHeight,
            usableWidth: usableSize.width
        )

        return WeatherTilesLayoutResult(
            itemFrames: frames,
            contentSize: size,
            visibleItemCount: frames.count
        )
    }

    func minimumRequiredHeight(
        for availableWidth: CGFloat,
        items: [WeatherTilesLayoutItem]
    ) -> CGFloat {
        let width = max(.zero, availableWidth)
        let usableWidth = max(
            .zero,
            width - metrics.contentInsets.left - metrics.contentInsets.right
        )

        guard
            !items.isEmpty,
            usableWidth > .zero,
            let firstRow = makeRows(
                items: items,
                usableWidth: usableWidth
            ).first
        else {
            return .zero
        }

        let minimumRowHeight = firstRow
            .map(\.minimumHeight)
            .max() ?? .zero

        return metrics.contentInsets.top
            + minimumRowHeight
            + metrics.contentInsets.bottom
    }
}

// MARK: - Helpers

private extension WeatherTilesLayout {

    struct VisibleLayout {
        let rows: [[WeatherTilesLayoutItem]]
    }

    func usableSize(in availableSize: CGSize) -> CGSize {
        CGSize(
            width: max(
                .zero,
                availableSize.width
                    - metrics.contentInsets.left
                    - metrics.contentInsets.right
            ),
            height: max(
                .zero,
                availableSize.height
                    - metrics.contentInsets.top
                    - metrics.contentInsets.bottom
            )
        )
    }

    func longestVisibleLayout(
        items: [WeatherTilesLayoutItem],
        usableSize: CGSize
    ) -> VisibleLayout {
        var bestLayout = VisibleLayout(rows: [])

        // Preserve presentation order by testing progressively longer
        // prefixes and keeping the last one that fits the viewport.
        for itemCount in 1...items.count {
            let candidateItems = Array(items.prefix(itemCount))
            let rows = makeRows(
                items: candidateItems,
                usableWidth: usableSize.width
            )

            guard fitsVertically(rows: rows, usableHeight: usableSize.height) else {
                break
            }

            bestLayout = VisibleLayout(rows: rows)
        }

        return bestLayout
    }

    func makeRows(
        items: [WeatherTilesLayoutItem],
        usableWidth: CGFloat
    ) -> [[WeatherTilesLayoutItem]] {
        guard !items.isEmpty, usableWidth > .zero else {
            return []
        }

        // Use the smallest row count that can contain every item, then choose
        // the most even contiguous distribution for that row count. This
        // avoids layouts such as 6 + 2 when a balanced 4 + 4 split also fits.
        for rowCount in 1...items.count {
            if let rows = balancedRows(
                items: items,
                rowCount: rowCount,
                usableWidth: usableWidth
            ) {
                return rows
            }
        }

        return []
    }

    func balancedRows(
        items: [WeatherTilesLayoutItem],
        rowCount: Int,
        usableWidth: CGFloat
    ) -> [[WeatherTilesLayoutItem]]? {
        var candidates: [[[WeatherTilesLayoutItem]]] = []

        collectRowCandidates(
            items: items,
            startIndex: .zero,
            remainingRowCount: rowCount,
            usableWidth: usableWidth,
            currentRows: [],
            candidates: &candidates
        )

        return candidates.min { first, second in
            isMoreBalanced(first, than: second)
        }
    }

    func collectRowCandidates(
        items: [WeatherTilesLayoutItem],
        startIndex: Int,
        remainingRowCount: Int,
        usableWidth: CGFloat,
        currentRows: [[WeatherTilesLayoutItem]],
        candidates: inout [[[WeatherTilesLayoutItem]]]
    ) {
        let remainingItemCount = items.count - startIndex
        guard remainingItemCount >= remainingRowCount else {
            return
        }

        if remainingRowCount == 1 {
            let finalRow = Array(items[startIndex...])
            guard rowFits(finalRow, usableWidth: usableWidth) else {
                return
            }

            candidates.append(currentRows + [finalRow])
            return
        }

        let maximumEndIndex = items.count - remainingRowCount
        guard startIndex <= maximumEndIndex else {
            return
        }

        for endIndex in startIndex...maximumEndIndex {
            let row = Array(items[startIndex...endIndex])
            guard rowFits(row, usableWidth: usableWidth) else {
                break
            }

            collectRowCandidates(
                items: items,
                startIndex: endIndex + 1,
                remainingRowCount: remainingRowCount - 1,
                usableWidth: usableWidth,
                currentRows: currentRows + [row],
                candidates: &candidates
            )
        }
    }

    func rowFits(
        _ row: [WeatherTilesLayoutItem],
        usableWidth: CGFloat
    ) -> Bool {
        let itemWidth = row.reduce(CGFloat.zero) {
            $0 + min(max(.zero, $1.preferredWidth), usableWidth)
        }
        let spacingWidth = CGFloat(max(.zero, row.count - 1))
            * metrics.horizontalSpacing

        return itemWidth + spacingWidth <= usableWidth
    }

    func isMoreBalanced(
        _ first: [[WeatherTilesLayoutItem]],
        than second: [[WeatherTilesLayoutItem]]
    ) -> Bool {
        let firstCounts = first.map(\.count)
        let secondCounts = second.map(\.count)
        let firstRange = (firstCounts.max() ?? .zero)
            - (firstCounts.min() ?? .zero)
        let secondRange = (secondCounts.max() ?? .zero)
            - (secondCounts.min() ?? .zero)

        if firstRange != secondRange {
            return firstRange < secondRange
        }

        // For equally balanced odd distributions, place the larger row first
        // so later rows do not visually outweigh the beginning of the grid.
        return firstCounts.lexicographicallyPrecedes(
            secondCounts,
            by: >
        )
    }

    func fitsVertically(
        rows: [[WeatherTilesLayoutItem]],
        usableHeight: CGFloat
    ) -> Bool {
        guard !rows.isEmpty else {
            return true
        }

        let minimumRowHeight = rows
            .flatMap { $0 }
            .map(\.minimumHeight)
            .max() ?? .zero

        // A common minimum row height keeps all rows aligned while ensuring
        // the tallest visible tile can display its content.
        let requiredHeight = CGFloat(rows.count) * minimumRowHeight
            + CGFloat(rows.count - 1) * metrics.verticalSpacing

        return requiredHeight <= usableHeight
    }

    func makeFrames(
        rows: [[WeatherTilesLayoutItem]],
        rowHeight: CGFloat,
        usableWidth: CGFloat
    ) -> [CGRect] {
        var frames: [CGRect] = []
        var y = metrics.contentInsets.top

        for row in rows {
            let preferredWidths = row.map {
                min(max(.zero, $0.preferredWidth), usableWidth)
            }
            let spacingWidth = CGFloat(max(.zero, row.count - 1))
                * metrics.horizontalSpacing
            let remainingWidth = max(
                .zero,
                usableWidth - preferredWidths.reduce(.zero, +) - spacingWidth
            )

            // Distribute each row's unused width evenly so the row fills the
            // container while retaining content-driven width differences.
            let additionalWidth = remainingWidth / CGFloat(row.count)
            var x = metrics.contentInsets.left

            for preferredWidth in preferredWidths {
                let width = preferredWidth + additionalWidth
                frames.append(
                    CGRect(
                        x: x,
                        y: y,
                        width: width,
                        height: rowHeight
                    )
                )
                x += width + metrics.horizontalSpacing
            }

            y += rowHeight + metrics.verticalSpacing
        }

        return frames
    }
}
