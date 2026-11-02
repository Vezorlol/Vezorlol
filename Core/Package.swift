// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "GiftCasesCore",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "GiftCasesCore", targets: ["GiftCasesCore"])],
    dependencies: [
        // На Apple-платформах используется CryptoKit; swift-crypto нужен только для Linux-тестов.
        .package(url: "https://github.com/apple/swift-crypto.git", from: "3.0.0")
    ],
    targets: [
        .target(
            name: "GiftCasesCore",
            dependencies: [.product(name: "Crypto", package: "swift-crypto", condition: .when(platforms: [.linux]))],
            resources: [.copy("Resources/gifts_catalog.json"), .copy("Resources/economy_rules.json"), .copy("Resources/gift_attributes.json")]
        ),
        .testTarget(name: "GiftCasesCoreTests", dependencies: ["GiftCasesCore"])
    ]
)
