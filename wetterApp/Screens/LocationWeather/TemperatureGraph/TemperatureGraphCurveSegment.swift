//
//  TemperatureGraphCurveSegment.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 14.06.2026.
//

import Foundation

struct TemperatureGraphCurveSegment: Equatable {
    let startPoint: CGPoint
    let firstControlPoint: CGPoint
    let secondControlPoint: CGPoint
    let endPoint: CGPoint
}
