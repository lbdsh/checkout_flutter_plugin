// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "checkout_com_flow",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(name: "checkout-com-flow", targets: ["checkout_com_flow"])
    ],
    dependencies: [
        .package(url: "https://github.com/checkout/checkout-ios-components", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "checkout_com_flow",
            dependencies: [
                .product(name: "CheckoutComponents", package: "checkout-ios-components"),
            ]
        )
    ]
)
