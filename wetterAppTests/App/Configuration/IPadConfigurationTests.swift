import XCTest
@testable import wetterApp

@MainActor
final class IPadConfigurationTests: XCTestCase {

    func testTargetSupportsIPhoneAndIPad() throws {
        let buildSettings = try appTargetBuildSettings()

        XCTAssertEqual(buildSettings.count, 2)
        XCTAssertTrue(
            buildSettings.allSatisfy {
                $0["TARGETED_DEVICE_FAMILY"] == "1,2"
            }
        )
    }

    func testApplicationDoesNotRequireFullScreen() throws {
        let buildSettings = try appTargetBuildSettings()
        let infoDictionary = try appInfoDictionary()

        XCTAssertTrue(
            buildSettings.allSatisfy {
                $0["INFOPLIST_KEY_UIRequiresFullScreen"] != "YES"
            }
        )
        XCTAssertNotEqual(
            infoDictionary["UIRequiresFullScreen"] as? Bool,
            true
        )
    }

    func testIPadSupportsPortraitAndLandscapeOrientations() throws {
        let expectedOrientations: Set<String> = [
            "UIInterfaceOrientationPortrait",
            "UIInterfaceOrientationPortraitUpsideDown",
            "UIInterfaceOrientationLandscapeLeft",
            "UIInterfaceOrientationLandscapeRight"
        ]

        let buildSettings = try appTargetBuildSettings()

        XCTAssertEqual(buildSettings.count, 2)
        for settings in buildSettings {
            let orientations = Set(
                settings[
                    "INFOPLIST_KEY_UISupportedInterfaceOrientations_iPad"
                ]?
                    .split(separator: " ")
                    .map(String.init) ?? []
            )

            XCTAssertEqual(orientations, expectedOrientations)
        }
    }

    func testLocationWeatherViewUsesSafeArea() {
        let view = LocationWeatherView()
        let verticalConstraints = view.constraints.filter {
            $0.firstItem === view.scrollView
                && ($0.firstAttribute == .top
                    || $0.firstAttribute == .bottom)
        }

        XCTAssertEqual(verticalConstraints.count, 2)
        XCTAssertTrue(
            verticalConstraints.allSatisfy {
                $0.secondItem === view.safeAreaLayoutGuide
            }
        )
    }
}

// MARK: - Helpers

private extension IPadConfigurationTests {

    var repositoryRoot: URL {
        URL(fileURLWithPath: #filePath)
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
            .deletingLastPathComponent()
    }

    func appTargetBuildSettings() throws -> [[String: String]] {
        let projectURL = repositoryRoot
            .appendingPathComponent("wetterApp.xcodeproj")
            .appendingPathComponent("project.pbxproj")
        let project = try String(contentsOf: projectURL)

        return project
            .components(separatedBy: "buildSettings = {")
            .dropFirst()
            .compactMap { section -> [String: String]? in
                guard let body = section.components(
                    separatedBy: "\n\t\t\t};"
                ).first else {
                    return nil
                }

                let settings = parseBuildSettings(body)
                guard settings["PRODUCT_BUNDLE_IDENTIFIER"]
                    == "com.bahadirovski.wetterApp" else {
                    return nil
                }

                return settings
            }
    }

    func parseBuildSettings(_ source: String) -> [String: String] {
        source
            .split(separator: "\n")
            .reduce(into: [:]) { settings, line in
                let parts = line.split(
                    separator: "=",
                    maxSplits: 1
                )
                guard parts.count == 2 else {
                    return
                }

                let key = parts[0]
                    .trimmingCharacters(in: .whitespaces)
                let value = parts[1]
                    .trimmingCharacters(in: .whitespaces)
                    .trimmingCharacters(in: CharacterSet(
                        charactersIn: "\";"
                    ))
                settings[key] = value
            }
    }

    func appInfoDictionary() throws -> [String: Any] {
        let infoURL = repositoryRoot
            .appendingPathComponent("wetterApp")
            .appendingPathComponent("Info.plist")
        let data = try Data(contentsOf: infoURL)
        let propertyList = try PropertyListSerialization.propertyList(
            from: data,
            format: nil
        )

        return try XCTUnwrap(propertyList as? [String: Any])
    }
}
