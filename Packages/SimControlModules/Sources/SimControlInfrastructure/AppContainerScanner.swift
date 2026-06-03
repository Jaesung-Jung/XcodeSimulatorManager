import Foundation
import SimControlDomain

/// Reads CoreSimulator app container folders and builds installed app entries.
public struct AppContainerScanner {
  struct ScanResult: Equatable {
    let apps: [InstalledApp]
    let warnings: [SimulatorWarning]
  }

  private struct BundleMetadata {
    let bundleID: String?
    let displayName: String?
    let version: String?
    let build: String?
    let iconPath: URL?
    let appGroupIDs: [String]
  }

  private struct DataContainerDetails {
    let databaseFiles: [URL]
    let size: Int64?
  }

  private static let metadataPlistName = ".com.apple.mobile_container_manager.metadata.plist"
  private static let metadataIdentifierKey = "MCMMetadataIdentifier"
  private static let appGroupEntitlementKey = "com.apple.security.application-groups"
  private static let databaseFileExtensions = Set(["db", "realm", "sqlite", "sqlite3"])

  private let fileManager: FileManager
  private let hidesSystemApps: Bool

  /// Creates an app container scanner.
  public init(
    fileManager: FileManager = .default,
    hidesSystemApps: Bool = false
  ) {
    self.fileManager = fileManager
    self.hidesSystemApps = hidesSystemApps
  }

  func scanInstalledApps(for device: SimulatorDevice) -> ScanResult {
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
    let appGroupsByID = scanAppGroups(
      in: dataPath,
      device: device,
      warnings: &warnings
    )
    let apps = scanBundleContainers(
      in: dataPath,
      device: device,
      dataContainersByBundleID: dataContainersByBundleID,
      appGroupsByID: appGroupsByID,
      warnings: &warnings
    )

    return ScanResult(
      apps: apps.sorted(by: installedAppSort),
      warnings: warnings
    )
  }

  private func scanBundleContainers(
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

  private func scanDataContainers(
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

  private func scanAppGroups(
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

  private func containerDirectories(
    at root: URL,
    device: SimulatorDevice,
    role: String,
    warningIDRole: String,
    warnings: inout [SimulatorWarning]
  ) -> [URL]? {
    guard directoryExists(at: root) else {
      warnings.append(
        warning(
          id: "apps-\(device.id)-missing-\(warningIDRole)-container",
          severity: .warning,
          category: .filesystem,
          message: "Device \(device.name) is missing its \(role) container folder.",
          relatedID: device.id
        )
      )
      return nil
    }

    do {
      let contents = try fileManager.contentsOfDirectory(
        at: root,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsPackageDescendants]
      )
      return contents
        .filter { directoryExists(at: $0) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-read-\(warningIDRole)-container-failed",
        message: "Device \(device.name) \(role) containers could not be read: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return nil
    }
  }

  private func metadataIdentifier(
    in container: URL,
    device: SimulatorDevice,
    containerRole: String,
    requiresIdentifier: Bool,
    warnings: inout [SimulatorWarning]
  ) -> String? {
    let metadataURL = container.appendingPathComponent(Self.metadataPlistName)
    guard fileManager.fileExists(atPath: metadataURL.path) else {
      warnings.append(
        warning(
          id: "apps-\(device.id)-\(containerRole)-\(container.lastPathComponent)-missing-metadata",
          severity: .warning,
          category: .app,
          message: "A \(containerRole) container in \(device.name) is missing CoreSimulator metadata.",
          relatedID: device.id
        )
      )
      return nil
    }

    guard let metadata = readPropertyList(
      at: metadataURL,
      device: device,
      warningID: "apps-\(device.id)-\(containerRole)-\(container.lastPathComponent)-malformed-metadata",
      warningMessage: "A \(containerRole) container in \(device.name) has malformed CoreSimulator metadata.",
      warnings: &warnings
    ) else {
      return nil
    }

    let identifier = nonEmpty(metadata[Self.metadataIdentifierKey] as? String)
    if requiresIdentifier && identifier == nil {
      warnings.append(
        warning(
          id: "apps-\(device.id)-\(containerRole)-\(container.lastPathComponent)-missing-identifier",
          severity: .warning,
          category: .app,
          message: "A \(containerRole) container in \(device.name) is missing a metadata identifier.",
          relatedID: device.id
        )
      )
    }

    return identifier
  }

  private func appBundle(
    in bundleContainer: URL,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> URL? {
    do {
      let contents = try fileManager.contentsOfDirectory(
        at: bundleContainer,
        includingPropertiesForKeys: [.isDirectoryKey],
        options: [.skipsHiddenFiles, .skipsPackageDescendants]
      )
      let appBundles = contents
        .filter { $0.pathExtension == "app" && directoryExists(at: $0) }
        .sorted { $0.lastPathComponent < $1.lastPathComponent }

      guard let appBundle = appBundles.first else {
        warnings.append(
          warning(
            id: "apps-\(device.id)-bundle-\(bundleContainer.lastPathComponent)-missing-app-bundle",
            severity: .warning,
            category: .app,
            message: "A bundle container in \(device.name) does not contain an app bundle and was skipped.",
            relatedID: device.id
          )
        )
        return nil
      }

      return appBundle
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-bundle-\(bundleContainer.lastPathComponent)-read-failed",
        message: "A bundle container in \(device.name) could not be read: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return nil
    }
  }

  private func readBundleMetadata(
    from appBundle: URL,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> BundleMetadata {
    let infoURL = appBundle.appendingPathComponent("Info.plist")
    guard let info = readPropertyList(
      at: infoURL,
      device: device,
      warningID: "apps-\(device.id)-bundle-\(appBundle.lastPathComponent)-malformed-info-plist",
      warningMessage: "App bundle \(appBundle.lastPathComponent) has malformed Info.plist metadata.",
      warnings: &warnings
    ) else {
      return BundleMetadata(
        bundleID: nil,
        displayName: nil,
        version: nil,
        build: nil,
        iconPath: nil,
        appGroupIDs: appGroupIDs(in: appBundle, device: device, warnings: &warnings)
      )
    }

    return BundleMetadata(
      bundleID: info["CFBundleIdentifier"] as? String,
      displayName: (info["CFBundleDisplayName"] as? String) ?? (info["CFBundleName"] as? String),
      version: info["CFBundleShortVersionString"] as? String,
      build: info["CFBundleVersion"] as? String,
      iconPath: iconPath(in: appBundle, info: info),
      appGroupIDs: appGroupIDs(in: appBundle, device: device, warnings: &warnings)
    )
  }

  private func appGroupIDs(
    in appBundle: URL,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> [String] {
    let entitlementURLs = [
      appBundle.appendingPathComponent("archived-expanded-entitlements.xcent"),
      appBundle.appendingPathComponent("embedded.entitlements"),
      appBundle.appendingPathComponent("Entitlements.plist")
    ]

    var groupIDs = Set<String>()

    for entitlementURL in entitlementURLs where fileManager.fileExists(atPath: entitlementURL.path) {
      guard let entitlements = readPropertyList(
        at: entitlementURL,
        device: device,
        warningID: "apps-\(device.id)-bundle-\(appBundle.lastPathComponent)-malformed-entitlements",
        warningMessage: "App bundle \(appBundle.lastPathComponent) has malformed entitlements metadata.",
        warnings: &warnings
      ) else {
        continue
      }

      let appGroupIDs = entitlements[Self.appGroupEntitlementKey] as? [String] ?? []
      for appGroupID in appGroupIDs {
        if let appGroupID = nonEmpty(appGroupID) {
          groupIDs.insert(appGroupID)
        }
      }
    }

    return groupIDs.sorted()
  }

  private func readPropertyList(
    at url: URL,
    device: SimulatorDevice,
    warningID: String,
    warningMessage: String,
    warnings: inout [SimulatorWarning]
  ) -> [String: Any]? {
    guard fileManager.fileExists(atPath: url.path) else {
      warnings.append(
        warning(
          id: "\(warningID)-missing",
          severity: .warning,
          category: .app,
          message: warningMessage,
          relatedID: device.id
        )
      )
      return nil
    }

    let data: Data
    do {
      data = try Data(contentsOf: url)
    } catch {
      warnings.append(fileWarning(
        id: warningID,
        message: "\(warningMessage) \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return nil
    }

    do {
      let propertyList = try PropertyListSerialization.propertyList(
        from: data,
        options: [],
        format: nil
      )

      guard let dictionary = propertyList as? [String: Any] else {
        warnings.append(
          warning(
            id: warningID,
            severity: .warning,
            category: .parsing,
            message: warningMessage,
            relatedID: device.id
          )
        )
        return nil
      }

      return dictionary
    } catch {
      warnings.append(
        warning(
          id: warningID,
          severity: .warning,
          category: .parsing,
          message: "\(warningMessage) \(error.localizedDescription)",
          relatedID: device.id
        )
      )
      return nil
    }
  }

  private func iconPath(in appBundle: URL, info: [String: Any]) -> URL? {
    let iconNames = iconNames(from: info)
    let appBundleContents = (try? fileManager.contentsOfDirectory(
      at: appBundle,
      includingPropertiesForKeys: [.isRegularFileKey],
      options: [.skipsHiddenFiles]
    )) ?? []

    for iconName in iconNames.reversed() {
      if let iconPath = matchingIconPath(named: iconName, in: appBundleContents) {
        return iconPath
      }
    }

    return appBundleContents
      .filter { $0.pathExtension == "png" && $0.lastPathComponent.hasPrefix("AppIcon") }
      .sorted { $0.lastPathComponent > $1.lastPathComponent }
      .first
  }

  private func iconNames(from info: [String: Any]) -> [String] {
    var iconNames: [String] = []

    if let iconFile = nonEmpty(info["CFBundleIconFile"] as? String) {
      iconNames.append(iconFile)
    }

    if let iconFiles = info["CFBundleIconFiles"] as? [String] {
      iconNames.append(contentsOf: iconFiles.compactMap(nonEmpty))
    }

    if let icons = info["CFBundleIcons"] as? [String: Any],
       let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let primaryIconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
      iconNames.append(contentsOf: primaryIconFiles.compactMap(nonEmpty))
    }

    if let icons = info["CFBundleIcons~ipad"] as? [String: Any],
       let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let primaryIconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
      iconNames.append(contentsOf: primaryIconFiles.compactMap(nonEmpty))
    }

    return Array(Set(iconNames)).sorted()
  }

  private func matchingIconPath(named iconName: String, in contents: [URL]) -> URL? {
    let iconBaseName = (iconName as NSString).deletingPathExtension
    let explicitIconName = iconName.hasSuffix(".png") ? iconName : "\(iconName).png"

    return contents
      .filter { iconURL in
        iconURL.lastPathComponent == explicitIconName
          || (iconURL.pathExtension == "png" && iconURL.deletingPathExtension().lastPathComponent.hasPrefix(iconBaseName))
      }
      .sorted { $0.lastPathComponent > $1.lastPathComponent }
      .first
  }

  private func dataContainerDetails(
    at dataContainer: URL?,
    device: SimulatorDevice,
    warnings: inout [SimulatorWarning]
  ) -> DataContainerDetails {
    guard let dataContainer else {
      return DataContainerDetails(databaseFiles: [], size: nil)
    }

    do {
      let subpaths = try fileManager.subpathsOfDirectory(atPath: dataContainer.path)
      var databaseFiles: [URL] = []
      var size: Int64 = 0

      for subpath in subpaths {
        let url = dataContainer.appendingPathComponent(subpath)
        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory),
              !isDirectory.boolValue
        else {
          continue
        }

        let resourceValues = try? url.resourceValues(forKeys: [.fileSizeKey])
        if let fileSize = resourceValues?.fileSize {
          size += Int64(fileSize)
        }

        if isDatabaseFile(url) {
          databaseFiles.append(url)
        }
      }

      return DataContainerDetails(
        databaseFiles: databaseFiles.sorted {
          $0.path.localizedStandardCompare($1.path) == .orderedAscending
        },
        size: size
      )
    } catch {
      warnings.append(fileWarning(
        id: "apps-\(device.id)-data-\(dataContainer.lastPathComponent)-scan-failed",
        message: "App data container \(dataContainer.lastPathComponent) in \(device.name) could not be scanned: \(error.localizedDescription)",
        relatedID: device.id,
        error: error
      ))
      return DataContainerDetails(databaseFiles: [], size: nil)
    }
  }

  private func isDatabaseFile(_ url: URL) -> Bool {
    let fileExtension = url.pathExtension.lowercased()
    if Self.databaseFileExtensions.contains(fileExtension) {
      return true
    }

    let fileName = url.lastPathComponent.lowercased()
    return fileName.hasSuffix(".db-shm")
      || fileName.hasSuffix(".db-wal")
      || fileName.hasSuffix(".sqlite-shm")
      || fileName.hasSuffix(".sqlite-wal")
  }

  private func directoryExists(at url: URL) -> Bool {
    var isDirectory: ObjCBool = false
    return fileManager.fileExists(atPath: url.path, isDirectory: &isDirectory) && isDirectory.boolValue
  }

  private func installedAppSort(_ first: InstalledApp, _ second: InstalledApp) -> Bool {
    if first.displayName.localizedStandardCompare(second.displayName) == .orderedSame {
      return first.bundleID.localizedStandardCompare(second.bundleID) == .orderedAscending
    }

    return first.displayName.localizedStandardCompare(second.displayName) == .orderedAscending
  }

  private func isSystemBundleID(_ bundleID: String) -> Bool {
    bundleID == "com.apple.Preferences" || bundleID.hasPrefix("com.apple.")
  }

  private func isSystemAppGroupID(_ groupID: String) -> Bool {
    groupID.hasPrefix("group.com.apple.")
      || groupID.hasPrefix("com.apple.")
      || groupID.contains(".groups.com.apple.")
  }

  private func nonEmpty(_ value: String?) -> String? {
    guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmedValue.isEmpty
    else {
      return nil
    }

    return trimmedValue
  }

  private func fileWarning(
    id: String,
    message: String,
    relatedID: String?,
    error: Error
  ) -> SimulatorWarning {
    let category: SimulatorWarning.Category = isPermissionError(error) ? .permissions : .filesystem
    return warning(
      id: id,
      severity: .warning,
      category: category,
      message: message,
      relatedID: relatedID
    )
  }

  private func isPermissionError(_ error: Error) -> Bool {
    let nsError = error as NSError
    if nsError.domain == NSCocoaErrorDomain,
       nsError.code == CocoaError.Code.fileReadNoPermission.rawValue {
      return true
    }

    if nsError.domain == NSPOSIXErrorDomain,
       nsError.code == Int(EACCES) || nsError.code == Int(EPERM) {
      return true
    }

    return false
  }

  private func warning(
    id: String,
    severity: SimulatorWarning.Severity,
    category: SimulatorWarning.Category,
    message: String,
    relatedID: String?
  ) -> SimulatorWarning {
    SimulatorWarning(
      id: id,
      severity: severity,
      category: category,
      message: message,
      relatedID: relatedID
    )
  }
}
