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
        var rows: [[WeatherTilesLayoutItem]] = []
        var currentRow: [WeatherTilesLayoutItem] = []
        var currentWidth: CGFloat = .zero

        for item in items {
            // A tile wider than the viewport occupies a row by itself and is
            // clamped so its frame never exceeds the available width.
            let preferredWidth = min(
                max(.zero, item.preferredWidth),
                usableWidth
            )
            let requiredWidth = currentRow.isEmpty
                ? preferredWidth
                : metrics.horizontalSpacing + preferredWidth

            // Rows are built greedily: move the next tile to a new row when
            // its measured minimum width no longer fits.
            if !currentRow.isEmpty, currentWidth + requiredWidth > usableWidth {
                rows.append(currentRow)
                currentRow = []
                currentWidth = .zero
            }

            currentRow.append(item)
            currentWidth += currentRow.count == 1
                ? preferredWidth
                : metrics.horizontalSpacing + preferredWidth
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        return rows
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
