//
//  TemperatureGraphCurveGeometry.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 14.06.2026.
//

import Foundation

struct TemperatureGraphCurveGeometry: Equatable {
    let leftSegment: TemperatureGraphCurveSegment?
    let currentPoint: CGPoint
    let rightSegment: TemperatureGraphCurveSegment?
}
