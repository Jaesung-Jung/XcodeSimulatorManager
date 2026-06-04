import Foundation
import SimControlDomain

extension AppContainerScanner {
  func scanDataContainers(
    in dataPath: URL,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> [String: URL] {
    let dataRoot = dataPath.appendingPathComponent(
      "Containers/Data/Application",
      isDirectory: true
    )

    guard let dataContainers = containerDirectories(
      at: dataRoot,
      device: device,
      role: "data application",
      warningIDRole: "data-application",
      warnings: &warnings
    ) else {
      return [:]
    }

    var dataContainersByBundleID: [String: URL] = [:]

    for dataContainer in dataContainers {
      guard let bundleID = metadataIdentifier(
        in: dataContainer,
        device: device,
        containerRole: "data",
        requiresIdentifier: true,
        warnings: &warnings
      ) else {
        continue
      }

      guard !hidesSystemApps || !isSystemBundleID(bundleID) else {
        continue
      }

      if dataContainersByBundleID[bundleID] == nil {
        dataContainersByBundleID[bundleID] = dataContainer
      }
    }

    return dataContainersByBundleID
  }
}

extension AppContainerScanner {
  func scanAppGroups(
    in dataPath: URL,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> [String: AppGroupContainer] {
    let appGroupRoot = dataPath.appendingPathComponent(
      "Containers/Shared/AppGroup",
      isDirectory: true
    )

    guard let appGroupContainers = containerDirectories(
      at: appGroupRoot,
      device: device,
      role: "App Group",
      warningIDRole: "app-group",
      warnings: &warnings
    ) else {
      return [:]
    }

    var appGroupsByID: [String: AppGroupContainer] = [:]

    for appGroupContainer in appGroupContainers {
      guard let groupID = metadataIdentifier(
        in: appGroupContainer,
        device: device,
        containerRole: "App Group",
        requiresIdentifier: true,
        warnings: &warnings
      ) else {
        continue
      }

      guard !hidesSystemApps || !isSystemAppGroupID(groupID) else {
        continue
      }

      if appGroupsByID[groupID] == nil {
        appGroupsByID[groupID] = AppGroupContainer(
          id: "\(device.id):\(groupID)",
          groupID: groupID,
          path: appGroupContainer
        )
      }
    }

    return appGroupsByID
  }
}
