import Foundation
import SimControlDomain

extension AppContainerScanner {
  func scanBundleContainers(
    in dataPath: URL,
    device: SimulatorDevice,
    homeScreenAppIDs: Set<String>?,
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
        isHiddenSystemApp: isHiddenSystemApp(
          bundleID: bundleID,
          metadata: bundleMetadata,
          homeScreenAppIDs: homeScreenAppIDs
        ),
        databaseFiles: dataContainerDetails.databaseFiles,
        dataContainerSize: dataContainerDetails.size
      )
      apps.append(app)
    }

    return apps
  }

  func scanRuntimeSystemApps(
    in runtimeRoot: URL?,
    device: SimulatorDevice,
    homeScreenAppIDs: Set<String>?,
    dataContainersByBundleID: [String: URL],
    appGroupsByID: [String: AppGroupContainer],
    warnings: inout [SimulatorWarning]
  ) -> [InstalledApp] {
    guard !hidesSystemApps,
          let runtimeRoot
    else {
      return []
    }

    let roots = [
      runtimeRoot.appendingPathComponent("Applications", isDirectory: true),
      runtimeRoot.appendingPathComponent("System/Applications", isDirectory: true)
    ]

    return roots.flatMap { root in
      systemApps(
        in: root,
        device: device,
        homeScreenAppIDs: homeScreenAppIDs,
        dataContainersByBundleID: dataContainersByBundleID,
        appGroupsByID: appGroupsByID,
        warnings: &warnings
      )
    }
  }

  func systemApps(
    in root: URL,
    device: SimulatorDevice,
    homeScreenAppIDs: Set<String>?,
    dataContainersByBundleID: [String: URL],
    appGroupsByID: [String: AppGroupContainer],
    warnings: inout [SimulatorWarning]
  ) -> [InstalledApp] {
    guard directoryExists(at: root) else {
      return []
    }

    let appBundles: [URL]
    do {
      appBundles = try fileManager.contentsOfDirectory(
        at: root,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      )
      .filter { $0.pathExtension == "app" && directoryExists(at: $0) }
      .sorted { $0.lastPathComponent < $1.lastPathComponent }
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-system-\(root.lastPathComponent)-read-failed",
        message: "System app bundles for \(device.name) could not be read: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return []
    }

    return appBundles.compactMap { appBundle in
      let bundleMetadata = readBundleMetadata(
        from: appBundle,
        device: device,
        warnings: &warnings
      )
      guard let bundleID = nonEmpty(bundleMetadata.bundleID),
            isSystemBundleID(bundleID)
      else {
        return nil
      }

      let dataContainer = dataContainersByBundleID[bundleID]
      let dataContainerDetails = dataContainerDetails(
        at: dataContainer,
        device: device,
        warnings: &warnings
      )
      let appGroups = bundleMetadata.appGroupIDs.compactMap { appGroupsByID[$0] }

      return InstalledApp(
        id: "\(device.id):\(bundleID)",
        bundleID: bundleID,
        displayName: nonEmpty(bundleMetadata.displayName) ?? bundleID,
        version: nonEmpty(bundleMetadata.version),
        build: nonEmpty(bundleMetadata.build),
        deviceID: device.id,
        bundleContainer: nil,
        dataContainer: dataContainer,
        appBundlePath: appBundle,
        appGroups: appGroups,
        iconPath: bundleMetadata.iconPath,
        isSystemApp: true,
        isHiddenSystemApp: isHiddenSystemApp(
          bundleID: bundleID,
          metadata: bundleMetadata,
          homeScreenAppIDs: homeScreenAppIDs
        ),
        databaseFiles: dataContainerDetails.databaseFiles,
        dataContainerSize: dataContainerDetails.size
      )
    }
  }

  func isHiddenSystemApp(
    bundleID: String,
    metadata: BundleMetadata,
    homeScreenAppIDs: Set<String>?
  ) -> Bool {
    guard isSystemBundleID(bundleID) else {
      return false
    }

    if let homeScreenAppIDs {
      return metadata.isHiddenSystemApp || !homeScreenAppIDs.contains(bundleID)
    }

    return metadata.isHiddenSystemApp
  }
}
