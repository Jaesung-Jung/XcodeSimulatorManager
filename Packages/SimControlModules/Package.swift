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
    .library(name: "MainWindowWorkflows", targets: ["MainWindowWorkflows"]),
    .library(name: "MainWindowFeatureSupport", targets: ["MainWindowFeatureSupport"]),
    .library(name: "MainWindowDisplaySupport", targets: ["MainWindowDisplaySupport"]),
    .library(name: "SimControlSharedUI", targets: ["SimControlSharedUI"]),
    .library(name: "DeviceListFeature", targets: ["DeviceListFeature"]),
    .library(name: "MainWindowFeature", targets: ["MainWindowFeature"]),
    .library(name: "SettingsFeature", targets: ["SettingsFeature"])
  ],
  dependencies: [
    .package(
      url: "https://github.com/pointfreeco/swift-dependencies",
      from: "1.12.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-composable-architecture.git",
      from: "1.25.0"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-case-paths",
      from: "1.7.3"
    ),
    .package(
      url: "https://github.com/pointfreeco/swift-perception",
      from: "2.0.10"
    ),
    .package(
      url: "https://github.com/pointfreeco/xctest-dynamic-overlay",
      from: "1.9.0"
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
        ),
        .product(
          name: "IssueReporting",
          package: "xctest-dynamic-overlay"
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
    .target(name: "MainWindowFeatureSupport"),
    .target(
      name: "MainWindowDisplaySupport",
      dependencies: ["SimControlDomain"]
    ),
    .target(name: "SimControlSharedUI"),
    .target(
      name: "DeviceListFeature",
      dependencies: [
        "MainWindowDisplaySupport",
        "MainWindowFeatureSupport",
        "SimControlDomain",
        "SimControlSharedUI",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .target(
      name: "MainWindowFeature",
      dependencies: [
        "DeviceListFeature",
        "MainWindowDisplaySupport",
        "MainWindowFeatureSupport",
        "MainWindowWorkflows",
        "SimControlClients",
        "SimControlSharedUI",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        ),
        .product(
          name: "CasePaths",
          package: "swift-case-paths"
        ),
        .product(
          name: "IssueReporting",
          package: "xctest-dynamic-overlay"
        ),
        .product(
          name: "Perception",
          package: "swift-perception"
        ),
        .product(
          name: "PerceptionCore",
          package: "swift-perception"
        )
      ]
    ),
    .target(name: "SettingsFeature"),
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
    ),
    .testTarget(
      name: "MainWindowFeatureTests",
      dependencies: [
        "DeviceListFeature",
        "MainWindowFeature",
        "MainWindowFeatureSupport",
        "SimControlClients",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "SettingsFeatureTests",
      dependencies: ["SettingsFeature"]
    ),
    .testTarget(
      name: "SimControlSharedUITests",
      dependencies: ["SimControlSharedUI"]
    ),
    .testTarget(
      name: "MainWindowFeatureSupportTests",
      dependencies: ["MainWindowFeatureSupport"]
    ),
    .testTarget(
      name: "MainWindowDisplaySupportTests",
      dependencies: [
        "MainWindowDisplaySupport",
        "SimControlDomain"
      ]
    ),
    .testTarget(
      name: "DeviceListFeatureTests",
      dependencies: [
        "DeviceListFeature",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    )
  ]
)
