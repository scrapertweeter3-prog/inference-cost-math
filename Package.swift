// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "InferenceCostMath",
    products: [
        .library(name: "InferenceCostMath", targets: ["InferenceCostMath"])
    ],
    targets: [
        .target(name: "InferenceCostMath")
    ]
)
