import UIKit

struct WeatherTilesLayoutMetrics: Equatable {

    let contentInsets: UIEdgeInsets
    let horizontalSpacing: CGFloat
    let verticalSpacing: CGFloat

    init(
        contentInsets: UIEdgeInsets = UIEdgeInsets(
            top: 16,
            left: 16,
            bottom: 16,
            right: 16
        ),
        horizontalSpacing: CGFloat = 12,
        verticalSpacing: CGFloat = 12
    ) {
        self.contentInsets = contentInsets
        self.horizontalSpacing = horizontalSpacing
        self.verticalSpacing = verticalSpacing
    }
}
