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
        availableWidth: CGFloat,
        itemCount: Int,
        contentSizeCategory: UIContentSizeCategory
    ) -> WeatherTilesLayoutResult {
        // Negative widths and item counts are treated as empty input so the
        // geometry remains safe while a view is transitioning between sizes.
        let width = max(.zero, availableWidth)
        let layoutConfiguration = configuration(for: width)

        // Width selects both the base column count and how many tiles are
        // allowed on screen. Accessibility text only reduces the columns;
        // it does not hide additional weather data.
        let columnCount = adjustedColumnCount(
            layoutConfiguration.columnCount,
            contentSizeCategory: contentSizeCategory
        )
        let visibleItemCount = min(
            max(.zero, itemCount),
            layoutConfiguration.maximumItemCount
        )

        guard visibleItemCount > 0 else {
            return WeatherTilesLayoutResult(
                itemFrames: [],
                contentSize: CGSize(width: width, height: .zero),
                visibleItemCount: .zero
            )
        }

        let tileWidth = itemWidth(
            availableWidth: width,
            columnCount: columnCount
        )
        let itemFrames = (0..<visibleItemCount).map { itemIndex in
            // Modulo selects the column and integer division advances the row.
            // For three columns: indices 0, 1, 2 are row 0; index 3 is row 1.
            let column = itemIndex % columnCount
            let row = itemIndex / columnCount

            // Height deliberately equals width so every tile remains square.
            return CGRect(
                x: metrics.contentInsets.left
                    + CGFloat(column)
                    * (tileWidth + metrics.horizontalSpacing),
                y: metrics.contentInsets.top
                    + CGFloat(row)
                    * (tileWidth + metrics.verticalSpacing),
                width: tileWidth,
                height: tileWidth
            )
        }

        // Ceiling accounts for a partially filled final row.
        let rowCount = Int(
            ceil(Double(visibleItemCount) / Double(columnCount))
        )

        // Content height includes the tile rows, only the spaces between rows,
        // and the outer vertical insets.
        let contentHeight = metrics.contentInsets.top
            + CGFloat(rowCount) * tileWidth
            + CGFloat(max(.zero, rowCount - 1)) * metrics.verticalSpacing
            + metrics.contentInsets.bottom

        return WeatherTilesLayoutResult(
            itemFrames: itemFrames,
            contentSize: CGSize(width: width, height: contentHeight),
            visibleItemCount: visibleItemCount
        )
    }
}

// MARK: - Helpers

private extension WeatherTilesLayout {

    struct Configuration {
        let columnCount: Int
        let maximumItemCount: Int
    }

    func configuration(for availableWidth: CGFloat) -> Configuration {
        // These breakpoints are based on the complete container width. Insets
        // are applied later when the exact square tile width is calculated.
        switch availableWidth {
        case ..<500:
            Configuration(
                columnCount: 2,
                maximumItemCount: metrics.compactMaximumItemCount
            )
        case ..<900:
            Configuration(
                columnCount: 3,
                maximumItemCount: metrics.mediumMaximumItemCount
            )
        default:
            Configuration(
                columnCount: 4,
                maximumItemCount: metrics.wideMaximumItemCount
            )
        }
    }

    func adjustedColumnCount(
        _ columnCount: Int,
        contentSizeCategory: UIContentSizeCategory
    ) -> Int {
        guard contentSizeCategory.isAccessibilityCategory else {
            return columnCount
        }

        // Fewer columns provide more room for enlarged text. Keeping at least
        // one column prevents division by zero for compact layouts.
        return max(1, columnCount - 1)
    }

    func itemWidth(
        availableWidth: CGFloat,
        columnCount: Int
    ) -> CGFloat {
        let horizontalInsets = metrics.contentInsets.left
            + metrics.contentInsets.right
        let totalSpacing = CGFloat(max(.zero, columnCount - 1))
            * metrics.horizontalSpacing

        // Insets and inter-column spaces do not belong to a tile. The
        // remaining width is shared equally across all columns.
        let usableWidth = max(
            .zero,
            availableWidth - horizontalInsets - totalSpacing
        )

        return usableWidth / CGFloat(columnCount)
    }
}
