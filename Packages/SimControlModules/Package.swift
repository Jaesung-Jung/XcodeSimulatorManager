// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SimControlModules",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "SimControlDomain", targets: ["SimControlDomain"]),
    .library(name: "SimControlInfrastructure", targets: ["SimControlInfrastructure"]),
    .library(name: "SimControlClients", targets: ["SimControlClients"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture.git",
      from: "1.25.5"
    )
  ],
  targets: [
    .target(name: "SimControlDomain"),
    .target(
      name: "SimControlInfrastructure",
      dependencies: ["SimControlDomain"]
    ),
    .target(
      name: "SimControlClients",
      dependencies: [
        "SimControlDomain",
        "SimControlInfrastructure",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "SimControlDomainTests",
      dependencies: ["SimControlDomain"]
    ),
    .testTarget(
      name: "SimControlInfrastructureTests",
      dependencies: ["SimControlInfrastructure"]
    )
  ]
)
