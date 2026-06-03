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
    .library(name: "SimControlClients", targets: ["SimControlClients"]),
    .library(name: "SimControlClientsLive", targets: ["SimControlClientsLive"]),
    .library(name: "MainWindowWorkflows", targets: ["MainWindowWorkflows"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "1.12.0"
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
        .product(
          name: "Dependencies",
          package: "swift-dependencies"
        )
      ]
    ),
    .target(
      name: "SimControlClientsLive",
      dependencies: [
        "SimControlClients",
        "SimControlInfrastructure"
      ]
    ),
    .target(
      name: "MainWindowWorkflows",
      dependencies: [
        "SimControlClients",
        "SimControlDomain"
      ]
    ),
    .testTarget(
      name: "SimControlDomainTests",
      dependencies: ["SimControlDomain"]
    ),
    .testTarget(
      name: "SimControlInfrastructureTests",
      dependencies: ["SimControlInfrastructure"]
    ),
    .testTarget(
      name: "MainWindowWorkflowsTests",
      dependencies: [
        "MainWindowWorkflows",
        "SimControlClients"
      ]
    )
  ]
)
