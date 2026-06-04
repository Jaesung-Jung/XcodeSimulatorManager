import Foundation

extension AppContainerScanner {
  func iconPath(in appBundle: URL, info: [String: Any]) -> URL? {
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

  func iconNames(from info: [String: Any]) -> [String] {
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

  func matchingIconPath(named iconName: String, in contents: [URL]) -> URL? {
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
}
