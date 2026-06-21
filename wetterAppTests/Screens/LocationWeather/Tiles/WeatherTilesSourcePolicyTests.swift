import XCTest

final class WeatherTilesSourcePolicyTests: XCTestCase {

    func testTilesSourceDoesNotUseForbiddenLayoutTypes() throws {
        let tilesDirectory = repositoryRoot
            .appendingPathComponent("wetterApp")
            .appendingPathComponent("Screens")
            .appendingPathComponent("LocationWeather")
            .appendingPathComponent("Tiles")
        let sourceFiles = try FileManager.default.contentsOfDirectory(
            at: tilesDirectory,
            includingPropertiesForKeys: nil
        ).filter {
            $0.pathExtension == "swift"
        }
        let forbiddenUsages = [
            "UIStackView",
            "NSLayoutConstraint.activate",
            "UICollectionView"
        ]

        for sourceFile in sourceFiles {
            let source = try String(contentsOf: sourceFile)

            for forbiddenUsage in forbiddenUsages {
                XCTAssertFalse(
                    source.contains(forbiddenUsage),
                    "\(sourceFile.lastPathComponent) contains \(forbiddenUsage)"
                )
            }
        }
    }
}

// MARK: - Helpers

private extension WeatherTilesSourcePolicyTests {

    var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }
}
