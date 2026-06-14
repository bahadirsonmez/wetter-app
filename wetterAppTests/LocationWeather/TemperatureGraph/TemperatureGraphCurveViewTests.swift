//
//  TemperatureGraphCurveViewTests.swift
//  wetterApp
//
//  Created by Bahadir Sonmez on 14.06.2026.
//

import XCTest
@testable import wetterApp

@MainActor
final class TemperatureGraphCurveViewTests: XCTestCase {

    func testCurvePassesThroughCurrentTemperaturePoint() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: nil,
            nextTemperature: nil,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        
        XCTAssertEqual(geometry.currentPoint, CGPoint(x: 50, y: 40))
        XCTAssertNil(geometry.leftSegment)
        XCTAssertNil(geometry.rightSegment)
    }

    func testRightCurveEndsAtSharedCellBoundary() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: nil,
            nextTemperature: 0,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        
        XCTAssertEqual(geometry.rightSegment?.endPoint, CGPoint(x: 100, y: 58))
    }

    func testAdjacentCurvesShareSameBoundaryPoint() {
        let leftCellGeometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: nil,
            nextTemperature: 0,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        let rightCellGeometry = makeGeometry(
            currentTemperature: 0,
            previousTemperature: 20,
            nextTemperature: nil,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        
        let rightCurveEnd = leftCellGeometry.rightSegment?.endPoint
        let leftCurveStart = rightCellGeometry.leftSegment?.startPoint
        
        XCTAssertEqual(rightCurveEnd?.y, leftCurveStart?.y)
    }

    func testAdjacentCurvesHaveMatchingBoundaryTangents() {
        let leftCellGeometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: nil,
            nextTemperature: 0,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        let rightCellGeometry = makeGeometry(
            currentTemperature: 0,
            previousTemperature: 20,
            nextTemperature: nil,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        
        guard let leftRightSegment = leftCellGeometry.rightSegment,
              let rightLeftSegment = rightCellGeometry.leftSegment else {
            XCTFail("Missing segments")
            return
        }
        
        let leftTangentX = leftRightSegment.endPoint.x - leftRightSegment.secondControlPoint.x
        let leftTangentY = leftRightSegment.endPoint.y - leftRightSegment.secondControlPoint.y
        
        let rightTangentX = rightLeftSegment.firstControlPoint.x - rightLeftSegment.startPoint.x
        let rightTangentY = rightLeftSegment.firstControlPoint.y - rightLeftSegment.startPoint.y
        
        XCTAssertEqual(leftTangentX, rightTangentX, accuracy: 0.001)
        XCTAssertEqual(leftTangentY, rightTangentY, accuracy: 0.001)
    }

    func testCurveControlPointsRemainInsideHorizontalSegment() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: 10,
            nextTemperature: 30,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        
        let leftSegment = geometry.leftSegment!
        XCTAssertGreaterThan(leftSegment.firstControlPoint.x, leftSegment.startPoint.x)
        XCTAssertLessThan(leftSegment.firstControlPoint.x, leftSegment.secondControlPoint.x)
        XCTAssertLessThan(leftSegment.secondControlPoint.x, leftSegment.endPoint.x)
        
        let rightSegment = geometry.rightSegment!
        XCTAssertGreaterThan(rightSegment.firstControlPoint.x, rightSegment.startPoint.x)
        XCTAssertLessThan(rightSegment.firstControlPoint.x, rightSegment.secondControlPoint.x)
        XCTAssertLessThan(rightSegment.secondControlPoint.x, rightSegment.endPoint.x)
    }

    func testEqualTemperaturesProduceHorizontalCurve() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: 20,
            nextTemperature: 20,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        
        let y = geometry.currentPoint.y
        XCTAssertEqual(geometry.leftSegment?.startPoint.y, y)
        XCTAssertEqual(geometry.leftSegment?.firstControlPoint.y, y)
        XCTAssertEqual(geometry.leftSegment?.secondControlPoint.y, y)
        XCTAssertEqual(geometry.leftSegment?.endPoint.y, y)
        
        XCTAssertEqual(geometry.rightSegment?.startPoint.y, y)
        XCTAssertEqual(geometry.rightSegment?.firstControlPoint.y, y)
        XCTAssertEqual(geometry.rightSegment?.secondControlPoint.y, y)
        XCTAssertEqual(geometry.rightSegment?.endPoint.y, y)
    }

    func testFirstItemOmitsLeftCurve() {
        let view = makeView(previousTemperature: nil, nextTemperature: 20)
        XCTAssertNil(view.leftCurveLayer.path)
        XCTAssertNil(view.leftFillLayer.path)
        XCTAssertNotNil(view.rightCurveLayer.path)
        XCTAssertNotNil(view.rightFillLayer.path)
        XCTAssertNotNil(view.pointLayer.path)
    }

    func testLastItemOmitsRightCurve() {
        let view = makeView(previousTemperature: 10, nextTemperature: nil)
        XCTAssertNotNil(view.leftCurveLayer.path)
        XCTAssertNotNil(view.leftFillLayer.path)
        XCTAssertNil(view.rightCurveLayer.path)
        XCTAssertNil(view.rightFillLayer.path)
        XCTAssertNotNil(view.pointLayer.path)
    }

    func testResetClearsCurvePaths() {
        let view = makeView(previousTemperature: 10, nextTemperature: 20)
        view.reset()
        XCTAssertNil(view.configuration)
        XCTAssertNil(view.leftCurveLayer.path)
        XCTAssertNil(view.rightCurveLayer.path)
        XCTAssertNil(view.leftFillLayer.path)
        XCTAssertNil(view.rightFillLayer.path)
        XCTAssertNil(view.pointLayer.path)
    }

    func testPointRemainsHorizontallyCentered() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: 10,
            nextTemperature: 30,
            minimumTemperature: 0,
            maximumTemperature: 40
        )
        XCTAssertEqual(geometry.currentPoint.x, 50)
    }

    func testCurveRecalculatesAfterBoundsChange() {
        let view = makeView(previousTemperature: 10, nextTemperature: 20)
        let initialPath = view.rightCurveLayer.path
        view.frame = CGRect(x: 0, y: 0, width: 200, height: 160)
        view.layoutIfNeeded()
        XCTAssertNotEqual(view.rightCurveLayer.path, initialPath)
    }
}

// MARK: - Helpers

private extension TemperatureGraphCurveViewTests {

    func makeGeometry(
        currentTemperature: Double,
        previousTemperature: Double?,
        nextTemperature: Double?,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) -> TemperatureGraphCurveGeometry {
        TemperatureGraphCurveView.makeGeometry(
            in: CGRect(x: 0, y: 0, width: 100, height: 80),
            configuration: .init(
                currentTemperature: currentTemperature,
                previousTemperature: previousTemperature,
                nextTemperature: nextTemperature,
                minimumTemperature: minimumTemperature,
                maximumTemperature: maximumTemperature
            )
        )
    }

    func makeView(
        previousTemperature: Double?,
        nextTemperature: Double?
    ) -> TemperatureGraphCurveView {
        let view = TemperatureGraphCurveView(
            frame: CGRect(x: 0, y: 0, width: 100, height: 80)
        )
        view.configure(
            currentTemperature: 15,
            previousTemperature: previousTemperature,
            nextTemperature: nextTemperature,
            minimumTemperature: 0,
            maximumTemperature: 30
        )
        view.layoutIfNeeded()
        return view
    }
}
