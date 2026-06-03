import Foundation
import SimControlDomain

extension AppContainerScanner {
  static let metadataPlistName = ".com.apple.mobile_container_manager.metadata.plist"
  static let metadataIdentifierKey = "MCMMetadataIdentifier"
  static let appGroupEntitlementKey = "com.apple.security.application-groups"

  func metadataIdentifier(
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

  func readBundleMetadata(
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

  func appGroupIDs(
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
}
