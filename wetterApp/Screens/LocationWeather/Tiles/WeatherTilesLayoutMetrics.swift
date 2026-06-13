import UIKit

struct WeatherTilesLayoutMetrics: Equatable {

    let contentInsets: UIEdgeInsets
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat
    let compactMaximumItemCount: Int
    let mediumMaximumItemCount: Int
    let wideMaximumItemCount: Int

    init(
        contentInsets: UIEdgeInsets = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        ),
        horizontalSpacing: CGFloat = 12,
        verticalSpacing: CGFloat = 12,
        compactMaximumItemCount: Int = 4,
        mediumMaximumItemCount: Int = 6,
        wideMaximumItemCount: Int = 8
    ) {
        self.contentInsets = contentInsets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
        self.compactMaximumItemCount = compactMaximumItemCount
        self.mediumMaximumItemCount = mediumMaximumItemCount
        self.wideMaximumItemCount = wideMaximumItemCount
    }
}
