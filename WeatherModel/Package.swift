// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WeatherModel",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WeatherModel",
            targets: ["WeatherModel"]
        )
    ],
    targets: [
        .target(
            name: "WeatherModel"
        ),
        .testTarget(
            name: "WeatherModelTests",
            dependencies: ["WeatherModel"]
        )
    ]
)
