// swift-tools-version: 6.2
// Vendored from github.com/avias8/spacetimedb-swift @ 994b0d4 (0.23.0). Local patches are marked `HOMER PATCH`.
import PackageDescription

let package = Package(
    name: "SpacetimeDB",
    platforms: [.iOS(.v18), .macOS(.v15)],
    products: [.library(name: "SpacetimeDB", targets: ["SpacetimeDB"])],
    targets: [.target(name: "SpacetimeDB")]
)
