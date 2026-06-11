// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "WeatherViewModel",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "WeatherViewModel",
            targets: ["WeatherViewModel"]
        )
    ],
    dependencies: [
        .package(path: "../WeatherModel")
    ],
    targets: [
        .target(
            name: "WeatherViewModel",
            dependencies: [
                .product(
                    name: "WeatherModel",
                    package: "WeatherModel"
                )
            ]
        ),
        .testTarget(
            name: "WeatherViewModelTests",
            dependencies: ["WeatherViewModel"]
        )
    ]
)
