import CoreGraphics
import Foundation
import ImageIO
import SimControlDomain

/// Resolves app icons stored in compiled asset catalogs on demand.
public struct AppIconAssetResolver {
  let fileManager: FileManager
  let iconCacheRootPath: String?

  /// Creates an asset catalog icon resolver.
  public init(
    fileManager: FileManager = .default,
    iconCacheRoot: URL? = nil
  ) {
    self.fileManager = fileManager
    self.iconCacheRootPath = (iconCacheRoot ?? AppContainerScanner.defaultIconCacheRoot())?.path
  }

  /// Returns a cached PNG path for an asset catalog icon, extracting it only when needed.
  public func iconPath(
    in appBundle: URL,
    platform: SimulatorPlatform?,
    deviceTypeID: String?,
    bundleID: String?,
    displayName: String?
  ) -> URL? {
    guard let iconCacheRootPath else {
      return nil
    }
    let iconCacheRoot = URL(fileURLWithPath: iconCacheRootPath, isDirectory: true)
    let assetsURL = appBundle.appendingPathComponent("Assets.car")
    guard fileManager.fileExists(atPath: assetsURL.path),
          let info = readInfoPlist(in: appBundle)
    else {
      return nil
    }

    let iconNames = AppContainerScanner().iconNames(from: info)
    for iconName in iconNames {
      let cacheURL = cachedIconURL(
        in: iconCacheRoot,
        bundleID: bundleID ?? info["CFBundleIdentifier"] as? String,
        appBundle: appBundle,
        assetName: iconName
      )
      if fileManager.fileExists(atPath: cacheURL.path) {
        return cacheURL
      }
    }

    let preferredTerms = assetCatalogPreferredTerms(
      info: info,
      appBundle: appBundle,
      bundleID: bundleID,
      displayName: displayName
    )
    let deviceIdiom = coreUIDeviceIdiom(platform: platform, deviceTypeID: deviceTypeID)
    guard let loadedIcon = Self.assetCatalogIconLoaderOverride?(
      assetsURL,
      iconNames,
      preferredTerms,
      deviceIdiom
    ) ?? CoreUIAssetCatalog.loadIcon(
      in: assetsURL,
      explicitNames: iconNames,
      preferredTerms: preferredTerms,
      deviceIdiom: deviceIdiom
    ) else {
      return nil
    }

    let cacheURL = cachedIconURL(
      in: iconCacheRoot,
      bundleID: bundleID ?? info["CFBundleIdentifier"] as? String,
      appBundle: appBundle,
      assetName: loadedIcon.name
    )
    if fileManager.fileExists(atPath: cacheURL.path) {
      return cacheURL
    }
    return writePNG(loadedIcon.image, to: cacheURL) ? cacheURL : nil
  }
}

extension AppIconAssetResolver {
  static var assetCatalogIconLoaderOverride: ((URL, [String], [String], Int) -> (name: String, image: CGImage)?)?

  func readInfoPlist(in appBundle: URL) -> [String: Any]? {
    let infoURL = appBundle.appendingPathComponent("Info.plist")
    guard let data = try? Data(contentsOf: infoURL),
          let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any]
    else {
      return nil
    }
    return plist
  }

  func assetCatalogPreferredTerms(
    info: [String: Any],
    appBundle: URL,
    bundleID: String?,
    displayName: String?
  ) -> [String] {
    [
      displayName,
      info["CFBundleDisplayName"] as? String,
      info["CFBundleName"] as? String,
      bundleID,
      info["CFBundleIdentifier"] as? String,
      appBundle.deletingPathExtension().lastPathComponent
    ]
    .compactMap(nonEmpty)
    .flatMap { value in
      value
        .components(separatedBy: CharacterSet.alphanumerics.inverted)
        .flatMap { component in
          component
            .replacingOccurrences(of: "TV", with: " TV")
            .replacingOccurrences(of: "Nano", with: " Nano")
            .components(separatedBy: " ")
        }
    }
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .filter { $0.count > 2 }
  }

  func coreUIDeviceIdiom(platform: SimulatorPlatform?, deviceTypeID: String?) -> Int {
    switch platform {
    case .iOS:
      return (deviceTypeID ?? "").lowercased().contains("ipad") ? 2 : 1
    case .tvOS:
      return 3
    case .watchOS:
      return 5
    case .visionOS:
      return 7
    case .unknown, .none:
      return 0
    }
  }

  func cachedIconURL(in iconCacheRoot: URL, bundleID: String?, appBundle: URL, assetName: String) -> URL {
    let cacheKey = "\(nonEmpty(bundleID) ?? appBundle.deletingPathExtension().lastPathComponent)-\(assetName)"
    let sanitizedCacheKey = String(cacheKey.map { character in
      character.isLetter || character.isNumber || character == "." || character == "-" || character == "_" ? character : "-"
    })
    return iconCacheRoot.appendingPathComponent("\(sanitizedCacheKey).png")
  }

  func writePNG(_ image: CGImage, to url: URL) -> Bool {
    do {
      try fileManager.createDirectory(
        at: url.deletingLastPathComponent(),
        withIntermediateDirectories: true
      )
      guard let destination = CGImageDestinationCreateWithURL(url as CFURL, "public.png" as CFString, 1, nil) else {
        return false
      }
      CGImageDestinationAddImage(destination, image, nil)
      return CGImageDestinationFinalize(destination)
    } catch {
      return false
    }
  }

  func nonEmpty(_ value: String?) -> String? {
    guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmedValue.isEmpty
    else {
      return nil
    }
    return trimmedValue
  }
}
