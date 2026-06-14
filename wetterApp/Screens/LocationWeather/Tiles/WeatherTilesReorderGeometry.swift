import UIKit

enum WeatherTilesReorderGeometry {

    static func destinationIndex(
        for location: CGPoint,
        visibleFrames: [CGRect]
    ) -> Int? {
        guard !visibleFrames.isEmpty else {
            return nil
        }

        // A direct hit takes precedence over distance calculations so dropping
        // on a tile always selects that exact tile as the destination.
        if let containingIndex = visibleFrames.firstIndex(
            where: { $0.contains(location) }
        ) {
            return containingIndex
        }

        // The union represents the reorderable viewport. Vertical drops
        // outside it are ignored instead of moving an item unexpectedly.
        let visibleBounds = visibleFrames.dropFirst().reduce(
            visibleFrames[0]
        ) {
            $0.union($1)
        }

        guard
            location.x >= visibleBounds.minX,
            location.y >= visibleBounds.minY,
            location.y <= visibleBounds.maxY
        else {
            return nil
        }

        // A drop beyond the trailing edge means "move to the end" while still
        // requiring the pointer to remain within the visible vertical range.
        if location.x > visibleBounds.maxX {
            return visibleFrames.indices.last
        }

        // Gaps between tiles belong to the tile whose center is closest to the
        // drop point, which works for unequal tile widths and multiple rows.
        return visibleFrames.indices.min {
            distanceSquared(
                from: location,
                to: visibleFrames[$0].center
            ) < distanceSquared(
                from: location,
                to: visibleFrames[$1].center
            )
        }
    }

    private static func distanceSquared(
        from point: CGPoint,
        to otherPoint: CGPoint
    ) -> CGFloat {
        // Squared distance preserves ordering without an unnecessary square
        // root for every destination candidate.
        let deltaX = point.x - otherPoint.x
        let deltaY = point.y - otherPoint.y
        return deltaX * deltaX + deltaY * deltaY
    }
}

private extension CGRect {

    var center: CGPoint {
        CGPoint(x: midX, y: midY)
    }
}
