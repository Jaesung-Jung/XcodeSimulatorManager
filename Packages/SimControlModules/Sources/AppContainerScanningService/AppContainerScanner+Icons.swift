import CoreGraphics
import Foundation
import ImageIO
import ObjectiveC.runtime
import SimControlDomain

extension AppContainerScanner {
  func iconPath(in appBundle: URL, info: [String: Any], device: SimulatorDevice) -> URL? {
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
      ?? assetCatalogIconPath(in: appBundle, info: info, device: device, iconNames: iconNames)
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
       let primaryIconName = icons["CFBundlePrimaryIcon"] as? String {
      iconNames.append(primaryIconName)
    }

    if let icons = info["CFBundleIcons"] as? [String: Any],
       let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let primaryIconName = primaryIcon["CFBundleIconName"] as? String {
      iconNames.append(primaryIconName)
    }

    if let icons = info["CFBundleIcons"] as? [String: Any],
       let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let primaryIconFiles = primaryIcon["CFBundleIconFiles"] as? [String] {
      iconNames.append(contentsOf: primaryIconFiles.compactMap(nonEmpty))
    }

    if let icons = info["CFBundleIcons~ipad"] as? [String: Any],
       let primaryIconName = icons["CFBundlePrimaryIcon"] as? String {
      iconNames.append(primaryIconName)
    }

    if let icons = info["CFBundleIcons~ipad"] as? [String: Any],
       let primaryIcon = icons["CFBundlePrimaryIcon"] as? [String: Any],
       let primaryIconName = primaryIcon["CFBundleIconName"] as? String {
      iconNames.append(primaryIconName)
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

  func assetCatalogIconPath(in appBundle: URL, info: [String: Any], device: SimulatorDevice, iconNames: [String]) -> URL? {
    guard let iconCacheRootPath else {
      return nil
    }
    let iconCacheRoot = URL(fileURLWithPath: iconCacheRootPath, isDirectory: true)

    let assetsURL = appBundle.appendingPathComponent("Assets.car")
    guard fileManager.fileExists(atPath: assetsURL.path) else {
      return nil
    }

    let preferredTerms = assetCatalogPreferredTerms(info: info, appBundle: appBundle)
    let deviceIdiom = coreUIDeviceIdiom(for: device)
    let loadedIcon = Self.assetCatalogIconLoaderOverride?(
      assetsURL,
      iconNames,
      preferredTerms,
      deviceIdiom
    ) ?? CoreUIAssetCatalog.loadIcon(
      in: assetsURL,
      explicitNames: iconNames,
      preferredTerms: preferredTerms,
      deviceIdiom: deviceIdiom
    )
    guard let loadedIcon else {
      return nil
    }

    let cacheURL = cachedIconURL(
      in: iconCacheRoot,
      bundleID: info["CFBundleIdentifier"] as? String,
      appBundle: appBundle,
      assetName: loadedIcon.name
    )
    return writePNG(loadedIcon.image, to: cacheURL) ? cacheURL : nil
  }

  static func assetCatalogIconCandidates(
    explicitNames: [String],
    catalogNames: [String],
    preferredTerms: [String]
  ) -> [String] {
    var candidates: [String] = []
    var seen = Set<String>()

    func append(_ name: String) {
      let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
      guard !name.isEmpty,
            !seen.contains(name)
      else {
        return
      }
      seen.insert(name)
      candidates.append(name)
    }

    explicitNames.forEach(append)
    catalogNames
      .filter { $0.localizedCaseInsensitiveContains("icon") }
      .sorted { lhs, rhs in
        if lhs == "AppIcon" {
          return true
        }
        if rhs == "AppIcon" {
          return false
        }
        let lhsMatchesPreferredTerm = preferredTerms.contains { lhs.localizedCaseInsensitiveContains($0) }
        let rhsMatchesPreferredTerm = preferredTerms.contains { rhs.localizedCaseInsensitiveContains($0) }
        if lhsMatchesPreferredTerm != rhsMatchesPreferredTerm {
          return lhsMatchesPreferredTerm
        }
        if lhs.contains("/") != rhs.contains("/") {
          return !lhs.contains("/")
        }
        return lhs < rhs
      }
      .forEach(append)

    return candidates
  }

  func assetCatalogPreferredTerms(info: [String: Any], appBundle: URL) -> [String] {
    [
      info["CFBundleDisplayName"] as? String,
      info["CFBundleName"] as? String,
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

  func coreUIDeviceIdiom(for device: SimulatorDevice) -> Int {
    switch device.platform {
    case .iOS:
      return device.deviceTypeID.lowercased().contains("ipad") ? 2 : 1
    case .tvOS:
      return 3
    case .watchOS:
      return 5
    case .visionOS:
      return 7
    case .unknown:
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
}

extension AppContainerScanner {
  static var assetCatalogIconLoaderOverride: ((URL, [String], [String], Int) -> (name: String, image: CGImage)?)?
}

struct CoreUIAssetCatalog {
  private static let frameworkPath = "/System/Library/PrivateFrameworks/CoreUI.framework/CoreUI"
  private static let catalogClassName = "CUICatalog"
  private static let initSelector = NSSelectorFromString("initWithURL:error:")
  private static let allImageNamesSelector = NSSelectorFromString("allImageNames")
  private static let imageSelector = NSSelectorFromString("image")
  private static let imageWithNameSelector = NSSelectorFromString("imageWithName:scaleFactor:deviceIdiom:")
  private static let iconImageWithNameSelector = NSSelectorFromString(
    "iconImageWithName:scaleFactor:deviceIdiom:deviceSubtype:displayGamut:layoutDirection:sizeClassHorizontal:sizeClassVertical:desiredSize:"
  )

  private let catalog: AnyObject
  private let catalogClass: NSObject.Type

  static func loadIcon(
    in assetsURL: URL,
    explicitNames: [String],
    preferredTerms: [String],
    deviceIdiom: Int
  ) -> (name: String, image: CGImage)? {
    guard let catalog = CoreUIAssetCatalog(url: assetsURL) else {
      return nil
    }

    let candidates = AppContainerScanner.assetCatalogIconCandidates(
      explicitNames: explicitNames,
      catalogNames: catalog.imageNames,
      preferredTerms: preferredTerms
    )
    for candidate in candidates {
      if let image = catalog.image(named: candidate, deviceIdiom: deviceIdiom) {
        return (candidate, image)
      }
    }
    return nil
  }

  init?(url: URL) {
    dlopen(Self.frameworkPath, RTLD_NOW)
    guard let catalogClass = NSClassFromString(Self.catalogClassName) as? NSObject.Type,
          let initMethod = class_getInstanceMethod(catalogClass, Self.initSelector),
          let allocatedCatalog = class_createInstance(catalogClass, 0) as AnyObject?
    else {
      return nil
    }

    typealias InitImplementation = @convention(c) (AnyObject, Selector, NSURL, UnsafeMutablePointer<NSError?>?) -> AnyObject?
    let initializer = unsafeBitCast(method_getImplementation(initMethod), to: InitImplementation.self)
    var error: NSError?
    guard let catalog = initializer(allocatedCatalog, Self.initSelector, url as NSURL, &error) else {
      return nil
    }

    self.catalog = catalog
    self.catalogClass = catalogClass
  }

  var imageNames: [String] {
    guard let method = class_getInstanceMethod(catalogClass, Self.allImageNamesSelector) else {
      return []
    }

    typealias AllImageNamesImplementation = @convention(c) (AnyObject, Selector) -> AnyObject?
    let allImageNames = unsafeBitCast(method_getImplementation(method), to: AllImageNamesImplementation.self)
    return allImageNames(catalog, Self.allImageNamesSelector) as? [String] ?? []
  }

  func image(named name: String, deviceIdiom: Int) -> CGImage? {
    imageWithName(named: name, deviceIdiom: deviceIdiom)
      ?? iconImageWithName(named: name, deviceIdiom: deviceIdiom)
  }

  private func imageWithName(named name: String, deviceIdiom: Int) -> CGImage? {
    guard let method = class_getInstanceMethod(catalogClass, Self.imageWithNameSelector) else {
      return nil
    }

    typealias ImageWithNameImplementation = @convention(c) (AnyObject, Selector, NSString, CGFloat, Int) -> AnyObject?
    let imageWithName = unsafeBitCast(method_getImplementation(method), to: ImageWithNameImplementation.self)
    guard let namedImage = imageWithName(catalog, Self.imageWithNameSelector, name as NSString, 1, deviceIdiom) else {
      return nil
    }
    return cgImage(from: namedImage)
  }

  private func iconImageWithName(named name: String, deviceIdiom: Int) -> CGImage? {
    guard let method = class_getInstanceMethod(catalogClass, Self.iconImageWithNameSelector) else {
      return nil
    }

    typealias IconImageWithNameImplementation = @convention(c) (
      AnyObject,
      Selector,
      NSString,
      CGFloat,
      Int,
      Int,
      Int,
      Int,
      Int,
      Int,
      CGSize
    ) -> AnyObject?
    let iconImageWithName = unsafeBitCast(method_getImplementation(method), to: IconImageWithNameImplementation.self)
    guard let namedImage = iconImageWithName(
      catalog,
      Self.iconImageWithNameSelector,
      name as NSString,
      1,
      deviceIdiom,
      0,
      0,
      0,
      0,
      0,
      CGSize(width: 1024, height: 1024)
    ) else {
      return nil
    }
    return cgImage(from: namedImage)
  }

  private func cgImage(from namedImage: AnyObject) -> CGImage? {
    guard let method = class_getInstanceMethod(object_getClass(namedImage), Self.imageSelector) else {
      return nil
    }

    typealias ImageImplementation = @convention(c) (AnyObject, Selector) -> Unmanaged<AnyObject>?
    let image = unsafeBitCast(method_getImplementation(method), to: ImageImplementation.self)
    guard let object = image(namedImage, Self.imageSelector)?.takeUnretainedValue(),
          CFGetTypeID(object) == CGImage.typeID
    else {
      return nil
    }
    return (object as! CGImage)
  }
}
