// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SimControlModules",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "SimControlDomain", targets: ["SimControlDomain"]),
    .library(name: "SimControlInfrastructure", targets: ["SimControlInfrastructure"])
  ],
  targets: [
    .target(name: "SimControlDomain"),
    .target(
      name: "SimControlInfrastructure",
      dependencies: ["SimControlDomain"]
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
