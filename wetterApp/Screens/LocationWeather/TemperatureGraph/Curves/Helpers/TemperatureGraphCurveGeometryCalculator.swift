import CoreGraphics

struct TemperatureGraphCurveGeometryCalculator {

    // MARK: - Properties

    let pointRadius: CGFloat

    // MARK: - Public Methods

    // Builds the drawable curve pieces for a single hourly cell.
    //
    // Each cell owns the dot at its center plus the left and right half-curves
    // that connect it to neighboring cells. The input configuration contains
    // nearby temperatures so this cell can compute the same cubic curve as its
    // neighbors and avoid visible gaps at cell boundaries.
    func makeGeometry(
        in bounds: CGRect,
        configuration: TemperatureGraphCurveConfiguration
    ) -> TemperatureGraphCurveGeometry {
        let currentTemperature = configuration.currentTemperature
        let currentY = yPosition(
            for: currentTemperature,
            in: bounds,
            minimumTemperature: configuration.minimumTemperature,
            maximumTemperature: configuration.maximumTemperature
        )
        let currentPoint = CGPoint(x: bounds.midX, y: currentY)
        let width = bounds.width

        let yPositionForTemperature = { (temperature: Double) -> CGFloat in
            yPosition(
                for: temperature,
                in: bounds,
                minimumTemperature: configuration.minimumTemperature,
                maximumTemperature: configuration.maximumTemperature
            )
        }

        let leftSegment = makeLeftSegment(
            bounds: bounds,
            width: width,
            currentPoint: currentPoint,
            currentTemperature: currentTemperature,
            currentY: currentY,
            configuration: configuration,
            yPosition: yPositionForTemperature
        )
        let rightSegment = makeRightSegment(
            bounds: bounds,
            width: width,
            currentPoint: currentPoint,
            currentTemperature: currentTemperature,
            currentY: currentY,
            configuration: configuration,
            yPosition: yPositionForTemperature
        )

        return TemperatureGraphCurveGeometry(
            leftSegment: leftSegment,
            currentPoint: currentPoint,
            rightSegment: rightSegment
        )
    }
}

// MARK: - Segment Geometry

private extension TemperatureGraphCurveGeometryCalculator {

    // Builds the half-curve entering the current dot from the previous hour.
    //
    // When there is no previous temperature this is the first visible point, so
    // the line stays flat from the left edge into the current dot.
    func makeLeftSegment(
        bounds: CGRect,
        width: CGFloat,
        currentPoint: CGPoint,
        currentTemperature: Double,
        currentY: CGFloat,
        configuration: TemperatureGraphCurveConfiguration,
        yPosition: (Double) -> CGFloat
    ) -> TemperatureGraphCurveSegment {
        guard let previousTemperature = configuration.previousTemperature else {
            return TemperatureGraphCurveSegment(
                startPoint: CGPoint(x: bounds.minX, y: currentY),
                firstControlPoint: CGPoint(x: bounds.minX + width / 6.0, y: currentY),
                secondControlPoint: CGPoint(x: bounds.minX + width / 3.0, y: currentY),
                endPoint: currentPoint
            )
        }

        // Build the cubic between previous -> current, then keep only the
        // right half because this cell starts at the midpoint between the two
        // hourly dots and ends at the current dot.
        let controlPoints = catmullRomControlPoints(
            beforeA: configuration.previous2Temperature,
            pointA: previousTemperature,
            pointB: currentTemperature,
            afterB: configuration.nextTemperature
        )
        let halves = splitBezier(
            p0: previousTemperature,
            p1: controlPoints.first,
            p2: controlPoints.second,
            p3: currentTemperature
        )
        let rightHalf = halves.rightHalf

        return TemperatureGraphCurveSegment(
            startPoint: CGPoint(x: bounds.minX, y: yPosition(rightHalf.start)),
            firstControlPoint: CGPoint(
                x: bounds.minX + width / 6.0,
                y: yPosition(rightHalf.c1)
            ),
            secondControlPoint: CGPoint(
                x: bounds.minX + width / 3.0,
                y: yPosition(rightHalf.c2)
            ),
            endPoint: currentPoint
        )
    }

    // Builds the half-curve leaving the current dot toward the next hour.
    //
    // When there is no next temperature this is the last visible point, so the
    // line stays flat from the current dot to the right edge.
    func makeRightSegment(
        bounds: CGRect,
        width: CGFloat,
        currentPoint: CGPoint,
        currentTemperature: Double,
        currentY: CGFloat,
        configuration: TemperatureGraphCurveConfiguration,
        yPosition: (Double) -> CGFloat
    ) -> TemperatureGraphCurveSegment {
        guard let nextTemperature = configuration.nextTemperature else {
            return TemperatureGraphCurveSegment(
                startPoint: currentPoint,
                firstControlPoint: CGPoint(x: bounds.midX + width / 6.0, y: currentY),
                secondControlPoint: CGPoint(x: bounds.midX + width / 3.0, y: currentY),
                endPoint: CGPoint(x: bounds.maxX, y: currentY)
            )
        }

        // Build the cubic between current -> next, then keep only the left
        // half because this cell starts at the current dot and ends at the
        // midpoint between the two hourly dots.
        let controlPoints = catmullRomControlPoints(
            beforeA: configuration.previousTemperature,
            pointA: currentTemperature,
            pointB: nextTemperature,
            afterB: configuration.next2Temperature
        )
        let halves = splitBezier(
            p0: currentTemperature,
            p1: controlPoints.first,
            p2: controlPoints.second,
            p3: nextTemperature
        )
        let leftHalf = halves.leftHalf

        return TemperatureGraphCurveSegment(
            startPoint: currentPoint,
            firstControlPoint: CGPoint(
                x: bounds.midX + width / 6.0,
                y: yPosition(leftHalf.c1)
            ),
            secondControlPoint: CGPoint(
                x: bounds.midX + width / 3.0,
                y: yPosition(leftHalf.c2)
            ),
            endPoint: CGPoint(x: bounds.maxX, y: yPosition(leftHalf.end))
        )
    }
}

// MARK: - Curve Math

private extension TemperatureGraphCurveGeometryCalculator {

    // Converts two neighboring temperature points into cubic Bezier controls.
    //
    // Catmull-Rom estimates the tangent from the surrounding points. That keeps
    // adjacent cells pointing in the same direction at shared boundaries. If an
    // outer neighbor is missing, the tangent falls back to the local slope so
    // the first and last graph segments still look natural.
    func catmullRomControlPoints(
        beforeA: Double?,
        pointA: Double,
        pointB: Double,
        afterB: Double?
    ) -> (first: Double, second: Double) {
        let tangentA = beforeA.map { (pointB - $0) / 2.0 } ?? pointB - pointA
        let tangentB = afterB.map { ($0 - pointA) / 2.0 } ?? pointB - pointA

        return (
            first: pointA + tangentA / 3.0,
            second: pointB - tangentB / 3.0
        )
    }

    // Splits a cubic Bezier curve exactly in half using De Casteljau.
    //
    // The graph is drawn by separate collection view cells. Splitting the same
    // cubic lets the left cell draw one half and the right cell draw the other
    // half, with the same midpoint and tangent at the boundary.
    func splitBezier(
        p0: Double,
        p1: Double,
        p2: Double,
        p3: Double
    ) -> (
        leftHalf: (start: Double, c1: Double, c2: Double, end: Double),
        rightHalf: (start: Double, c1: Double, c2: Double, end: Double)
    ) {
        let m0 = (p0 + p1) / 2.0
        let m1 = (p1 + p2) / 2.0
        let m2 = (p2 + p3) / 2.0

        let q0 = (m0 + m1) / 2.0
        let q1 = (m1 + m2) / 2.0

        let mid = (q0 + q1) / 2.0

        return (
            leftHalf: (start: p0, c1: m0, c2: q0, end: mid),
            rightHalf: (start: mid, c1: q1, c2: m2, end: p3)
        )
    }

    // Maps a temperature into a y-position inside the cell bounds.
    //
    // Higher temperatures are drawn closer to the top. Equal min/max values are
    // centered to avoid division by zero, and the result is clamped so unusual
    // input cannot place the dot outside the visible cell.
    func yPosition(
        for temperature: Double,
        in bounds: CGRect,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) -> CGFloat {
        let lowerBound = min(minimumTemperature, maximumTemperature)
        let upperBound = max(minimumTemperature, maximumTemperature)

        guard upperBound > lowerBound else {
            return bounds.midY
        }

        let normalizedValue = (temperature - lowerBound) / (upperBound - lowerBound)
        let clampedValue = min(max(normalizedValue, 0), 1)
        // Keep the dot fully inside the cell while preserving high temperatures near the top.
        let verticalInset = min(pointRadius, bounds.height / 2)
        let drawableHeight = max(bounds.height - verticalInset * 2, 0)

        return bounds.maxY - verticalInset - CGFloat(clampedValue) * drawableHeight
    }
}
