import Foundation
import SimControlDomain

/// Reads CoreSimulator app container folders and builds installed app entries.
public struct AppContainerScanner {
  public struct ScanResult: Equatable {
    public let apps: [InstalledApp]
    public let warnings: [SimulatorWarning]

    public init(apps: [InstalledApp], warnings: [SimulatorWarning]) {
      self.apps = apps
      self.warnings = warnings
    }
  }

  let fileManager: FileManager
  let hidesSystemApps: Bool

  /// Creates an app container scanner.
  public init(
    fileManager: FileManager = .default,
    hidesSystemApps: Bool = false
  ) {
    self.fileManager = fileManager
    self.hidesSystemApps = hidesSystemApps
  }

  public func scanInstalledApps(
    for device: SimulatorDevice,
    runtimeRoot: URL? = nil
  ) -> ScanResult {
    var warnings: [SimulatorWarning] = []

    guard let dataPath = device.dataPath else {
      return ScanResult(
        apps: [],
        warnings: [
          warning(
            id: "apps-\(device.id)-missing-data-path",
            severity: .warning,
            category: .filesystem,
            message: "Device \(device.name) does not report a data path, so installed apps could not be scanned.",
            relatedID: device.id
          )
        ]
      )
    }

    let dataContainersByBundleID = scanDataContainers(
      in: dataPath,
      device: device,
      warnings: &warnings
    )
    let homeScreenAppIDs = readHomeScreenAppIDs(in: dataPath)
    let appGroupsByID = scanAppGroups(
      in: dataPath,
      device: device,
      warnings: &warnings
    )
    let apps = scanBundleContainers(
      in: dataPath,
      device: device,
      homeScreenAppIDs: homeScreenAppIDs,
      dataContainersByBundleID: dataContainersByBundleID,
      appGroupsByID: appGroupsByID,
      warnings: &warnings
    )
    let systemApps = scanRuntimeSystemApps(
      in: runtimeRoot,
      device: device,
      homeScreenAppIDs: homeScreenAppIDs,
      warnings: &warnings
    )

    return ScanResult(
      apps: uniqued(apps + systemApps).sorted(by: installedAppSort),
      warnings: warnings
    )
  }
}
