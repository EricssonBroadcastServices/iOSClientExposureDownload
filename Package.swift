// swift-tools-version:5.5
// Uncategorized Group// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "iOSClientExposureDownload",
    platforms: [.iOS(.v12)],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "iOSClientExposureDownload",
            targets: ["iOSClientExposureDownload"]
        ),
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(
            url: "https://github.com/EricssonBroadcastServices/iOSClientExposure",
            from: "3.5.0"
        ),
        .package(
            url: "https://github.com/EricssonBroadcastServices/iOSClientDownload",
            from: "3.0.3"
        ),
        .package(
            url: "https://github.com/Quick/Quick.git",
            from: "4.0.0"
        ),
        .package(
            url: "https://github.com/Quick/Nimble.git",
            from: "9.1.0"
        ),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "iOSClientExposureDownload",
            dependencies: [
                "iOSClientDownload",
                "iOSClientExposure"
            ],
            exclude: ["Info.plist"],
            resources: [.copy("PrivacyInfo.xcprivacy")]
        ),
        .target(
            name: "iOSClientExposureDownloadObjc",
            dependencies: []
        ),
        .testTarget(
            name: "iOSClientExposureDownloadTests",
            dependencies: [
                "iOSClientExposureDownload",
                "iOSClientDownload",
                "Quick",
                "Nimble"
            ],
            exclude: ["Info.plist"]
        ),
    ]
)
