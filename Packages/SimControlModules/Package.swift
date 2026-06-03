// swift-tools-version: 5.9

import PackageDescription

let package = Package(
  name: "SimControlModules",
  platforms: [
    .macOS(.v14)
  ],
  products: [
    .library(name: "SimControlDomain", targets: ["SimControlDomain"]),
    .library(name: "CommandExecutionService", targets: ["CommandExecutionService"]),
    .library(name: "CoreSimulatorService", targets: ["CoreSimulatorService"]),
    .library(name: "AppContainerScanningService", targets: ["AppContainerScanningService"]),
    .library(name: "PathActionService", targets: ["PathActionService"]),
    .library(name: "AppSandboxResetService", targets: ["AppSandboxResetService"]),
    .library(name: "SimControlInfrastructure", targets: ["SimControlInfrastructure"]),
    .library(name: "SimControlClients", targets: ["SimControlClients"]),
    .library(name: "SimControlClientsLive", targets: ["SimControlClientsLive"]),
    .library(name: "MainWindowWorkflows", targets: ["MainWindowWorkflows"]),
    .library(name: "MainWindowFeatureSupport", targets: ["MainWindowFeatureSupport"]),
    .library(name: "MainWindowDisplaySupport", targets: ["MainWindowDisplaySupport"]),
    .library(name: "SimControlSharedUI", targets: ["SimControlSharedUI"]),
    .library(name: "DeviceListFeature", targets: ["DeviceListFeature"]),
    .library(name: "InstalledAppsFeature", targets: ["InstalledAppsFeature"]),
    .library(name: "DeveloperToolsFeature", targets: ["DeveloperToolsFeature"]),
    .library(name: "DeviceDetailFeature", targets: ["DeviceDetailFeature"]),
    .library(name: "InspectorFeature", targets: ["InspectorFeature"]),
    .library(name: "SidebarFeature", targets: ["SidebarFeature"]),
    .library(name: "WorkspaceFeature", targets: ["WorkspaceFeature"]),
    .library(name: "MenuBarFeature", targets: ["MenuBarFeature"]),
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
      name: "CommandExecutionService",
      dependencies: ["SimControlDomain"]
    ),
    .target(
      name: "CoreSimulatorService",
      dependencies: [
        "CommandExecutionService",
        "SimControlDomain"
      ]
    ),
    .target(
      name: "AppContainerScanningService",
      dependencies: ["SimControlDomain"]
    ),
    .target(
      name: "PathActionService",
      dependencies: ["SimControlDomain"]
    ),
    .target(
      name: "AppSandboxResetService",
      dependencies: ["SimControlDomain"]
    ),
    .target(
      name: "SimControlInfrastructure",
      dependencies: [
        "AppContainerScanningService",
        "AppSandboxResetService",
        "CommandExecutionService",
        "CoreSimulatorService",
        "PathActionService",
        "SimControlDomain"
      ]
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
      name: "InstalledAppsFeature",
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
      name: "DeveloperToolsFeature",
      dependencies: [
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
      name: "DeviceDetailFeature",
      dependencies: [
        "DeveloperToolsFeature",
        "InstalledAppsFeature",
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
      name: "InspectorFeature",
      dependencies: [
        "MainWindowDisplaySupport",
        "SimControlDomain",
        "SimControlSharedUI",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .target(
      name: "SidebarFeature",
      dependencies: [
        "MainWindowDisplaySupport",
        "MainWindowFeatureSupport",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .target(
      name: "WorkspaceFeature",
      dependencies: [
        "DeveloperToolsFeature",
        "DeviceDetailFeature",
        "DeviceListFeature",
        "InspectorFeature",
        "InstalledAppsFeature",
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
        "DeveloperToolsFeature",
        "DeviceDetailFeature",
        "DeviceListFeature",
        "InspectorFeature",
        "InstalledAppsFeature",
        "SidebarFeature",
        "WorkspaceFeature",
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
    .target(
      name: "MenuBarFeature",
      dependencies: [
        "DeviceDetailFeature",
        "DeviceListFeature",
        "InstalledAppsFeature",
        "MainWindowDisplaySupport",
        "MainWindowFeature",
        "MainWindowFeatureSupport",
        "SimControlDomain",
        "WorkspaceFeature",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
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
      name: "CommandExecutionServiceTests",
      dependencies: [
        "CommandExecutionService",
        "SimControlDomain"
      ]
    ),
    .testTarget(
      name: "CoreSimulatorServiceTests",
      dependencies: [
        "CoreSimulatorService",
        "SimControlDomain"
      ]
    ),
    .testTarget(
      name: "AppContainerScanningServiceTests",
      dependencies: [
        "AppContainerScanningService",
        "SimControlDomain"
      ]
    ),
    .testTarget(
      name: "PathActionServiceTests",
      dependencies: [
        "PathActionService",
        "SimControlDomain"
      ]
    ),
    .testTarget(
      name: "AppSandboxResetServiceTests",
      dependencies: [
        "AppSandboxResetService",
        "SimControlDomain"
      ]
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
        "DeveloperToolsFeature",
        "DeviceDetailFeature",
        "DeviceListFeature",
        "InspectorFeature",
        "InstalledAppsFeature",
        "SidebarFeature",
        "WorkspaceFeature",
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
    ),
    .testTarget(
      name: "InstalledAppsFeatureTests",
      dependencies: [
        "InstalledAppsFeature",
        "MainWindowFeatureSupport",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "DeveloperToolsFeatureTests",
      dependencies: [
        "DeveloperToolsFeature",
        "MainWindowFeatureSupport",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "DeviceDetailFeatureTests",
      dependencies: [
        "DeviceDetailFeature",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "InspectorFeatureTests",
      dependencies: [
        "InspectorFeature",
        "SimControlDomain",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "SidebarFeatureTests",
      dependencies: [
        "MainWindowFeatureSupport",
        "SidebarFeature",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "WorkspaceFeatureTests",
      dependencies: [
        "MainWindowFeatureSupport",
        "WorkspaceFeature",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    ),
    .testTarget(
      name: "MenuBarFeatureTests",
      dependencies: [
        "MainWindowFeature",
        "MenuBarFeature",
        .product(
          name: "ComposableArchitecture",
          package: "swift-composable-architecture"
        )
      ]
    )
  ]
)
