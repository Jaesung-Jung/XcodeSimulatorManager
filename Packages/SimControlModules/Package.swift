// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SimControlModules",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "SimControlDomain", targets: ["SimControlDomain"])
  ],
  targets: [
    .target(name: "SimControlDomain"),
    .testTarget(
      name: "SimControlDomainTests",
      dependencies: ["SimControlDomain"]
    )
  ]
)
