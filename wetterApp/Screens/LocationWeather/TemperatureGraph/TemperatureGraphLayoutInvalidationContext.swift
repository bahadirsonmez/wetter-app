import UIKit

final class TemperatureGraphLayoutInvalidationContext:
    UICollectionViewLayoutInvalidationContext {

    var invalidatesGeometry = false
    var invalidatesStickyHeadersOnly = false
}
