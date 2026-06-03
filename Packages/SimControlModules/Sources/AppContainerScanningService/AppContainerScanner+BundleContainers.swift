import Foundation
import SimControlDomain

extension AppContainerScanner {
  func scanBundleContainers(
    in dataPath: URL,
    device: SimulatorDevice,
    dataContainersByBundleID: [String: URL],
    appGroupsByID: [String: AppGroupContainer],
    warnings: inout [SimulatorWarning]
  ) -> [InstalledApp] {
    let bundleRoot = dataPath.appendingPathComponent(
      "Containers/Bundle/Application",
      isDirectory: true
    )

    guard let bundleContainers = containerDirectories(
      at: bundleRoot,
      device: device,
      role: "bundle application",
      warningIDRole: "bundle-application",
      warnings: &warnings
    ) else {
      return []
    }

    var apps: [InstalledApp] = []

    for bundleContainer in bundleContainers {
      let metadataBundleID = metadataIdentifier(
        in: bundleContainer,
        device: device,
        containerRole: "bundle",
        requiresIdentifier: false,
        warnings: &warnings
      )

      guard let appBundlePath = appBundle(in: bundleContainer, device: device, warnings: &warnings) else {
        continue
      }

      let bundleMetadata = readBundleMetadata(
        from: appBundlePath,
        device: device,
        warnings: &warnings
      )
      guard let bundleID = nonEmpty(bundleMetadata.bundleID) ?? metadataBundleID else {
        warnings.append(
          warning(
            id: "apps-\(device.id)-bundle-\(bundleContainer.lastPathComponent)-missing-bundle-id",
            severity: .warning,
            category: .app,
            message: "An installed app in \(device.name) is missing a bundle identifier and was skipped.",
            relatedID: device.id
          )
        )
        continue
      }

      guard !hidesSystemApps || !isSystemBundleID(bundleID) else {
        continue
      }

      let dataContainer = dataContainersByBundleID[bundleID]
      let dataContainerDetails = dataContainerDetails(
        at: dataContainer,
        device: device,
        warnings: &warnings
      )
      let appGroups = bundleMetadata.appGroupIDs.compactMap { appGroupsByID[$0] }
      let app = InstalledApp(
        id: "\(device.id):\(bundleID)",
        bundleID: bundleID,
        displayName: nonEmpty(bundleMetadata.displayName) ?? bundleID,
        version: nonEmpty(bundleMetadata.version),
        build: nonEmpty(bundleMetadata.build),
        deviceID: device.id,
        bundleContainer: bundleContainer,
        dataContainer: dataContainer,
        appBundlePath: appBundlePath,
        appGroups: appGroups,
        iconPath: bundleMetadata.iconPath,
        isSystemApp: isSystemBundleID(bundleID),
        databaseFiles: dataContainerDetails.databaseFiles,
        dataContainerSize: dataContainerDetails.size
      )
      apps.append(app)
    }

    return apps
  }
}
