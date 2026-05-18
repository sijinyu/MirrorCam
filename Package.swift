// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "MirrorCam",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .library(
            name: "MirrorCamLib",
            targets: ["MirrorCam"]
        ),
        .executable(
            name: "MirrorCamApp",
            targets: ["MirrorCamApp"]
        ),
    ],
    targets: [
        .target(
            name: "MirrorCam",
            dependencies: []
        ),
        .executableTarget(
            name: "MirrorCamApp",
            dependencies: ["MirrorCam"]
        ),
        .testTarget(
            name: "MirrorCamTests",
            dependencies: ["MirrorCam"]
        ),
    ]
)
