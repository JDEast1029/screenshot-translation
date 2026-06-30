// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ScreenshotTranslator",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ScreenshotTranslator", targets: ["ScreenshotTranslator"])
    ],
    targets: [
        .executableTarget(
            name: "ScreenshotTranslator",
            path: "Sources/ScreenshotTranslator"
        )
    ]
)
