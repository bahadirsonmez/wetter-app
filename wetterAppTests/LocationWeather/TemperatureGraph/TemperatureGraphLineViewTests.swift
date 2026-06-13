import XCTest
@testable import wetterApp

@MainActor
final class TemperatureGraphLineViewTests: XCTestCase {

    func testGeometryPlacesCurrentPointAtHorizontalCenter() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: nil,
            nextTemperature: nil,
            minimumTemperature: 0,
            maximumTemperature: 40
        )

        XCTAssertEqual(geometry.currentPoint, CGPoint(x: 50, y: 40))
    }

    func testGeometryMapsPreviousAndNextTemperaturesToCellEdges() {
        let geometry = makeGeometry(
            currentTemperature: 20,
            previousTemperature: 40,
            nextTemperature: 0,
            minimumTemperature: 0,
            maximumTemperature: 40
        )

        XCTAssertEqual(geometry.previousPoint, CGPoint(x: 0, y: 22))
        XCTAssertEqual(geometry.nextPoint, CGPoint(x: 100, y: 58))
    }

    func testGeometryCentersPointsWhenAllTemperaturesAreEqual() {
        let geometry = makeGeometry(
            currentTemperature: 12,
            previousTemperature: 12,
            nextTemperature: 12,
            minimumTemperature: 12,
            maximumTemperature: 12
        )

        XCTAssertEqual(geometry.previousPoint?.y, 40)
        XCTAssertEqual(geometry.currentPoint.y, 40)
        XCTAssertEqual(geometry.nextPoint?.y, 40)
    }

    func testConfigureWithoutPreviousTemperatureOmitsLeftLine() {
        let view = makeView(
            previousTemperature: nil,
            nextTemperature: 20
        )

        XCTAssertNil(view.leftLineLayer.path)
        XCTAssertNotNil(view.rightLineLayer.path)
        XCTAssertNotNil(view.pointLayer.path)
    }

    func testConfigureWithoutNextTemperatureOmitsRightLine() {
        let view = makeView(
            previousTemperature: 10,
            nextTemperature: nil
        )

        XCTAssertNotNil(view.leftLineLayer.path)
        XCTAssertNil(view.rightLineLayer.path)
        XCTAssertNotNil(view.pointLayer.path)
    }

    func testResetClearsConfigurationAndPaths() {
        let view = makeView(
            previousTemperature: 10,
            nextTemperature: 20
        )

        view.reset()

        XCTAssertNil(view.configuration)
        XCTAssertNil(view.leftLineLayer.path)
        XCTAssertNil(view.rightLineLayer.path)
        XCTAssertNil(view.pointLayer.path)
    }
}

// MARK: - Helpers

private extension TemperatureGraphLineViewTests {

    func makeGeometry(
        currentTemperature: Double,
        previousTemperature: Double?,
        nextTemperature: Double?,
        minimumTemperature: Double,
        maximumTemperature: Double
    ) -> TemperatureGraphLineView.Geometry {
        TemperatureGraphLineView.makeGeometry(
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
    ) -> TemperatureGraphLineView {
        let view = TemperatureGraphLineView(
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
