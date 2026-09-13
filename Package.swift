// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "TFYSwiftCalendarkit",
    defaultLocalization: "en",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "TFYSwiftCalendarkit",
            targets: ["TFYSwiftCalendarkit"]
        )
    ],
    targets: [
        .target(
            name: "TFYSwiftCalendarkit",
            path: "Sources/TFYSwiftCalendarkit",
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .testTarget(
            name: "TFYSwiftCalendarkitTests",
            dependencies: ["TFYSwiftCalendarkit"],
            path: "Tests/TFYSwiftCalendarkitTests"
        )
    ]
)
