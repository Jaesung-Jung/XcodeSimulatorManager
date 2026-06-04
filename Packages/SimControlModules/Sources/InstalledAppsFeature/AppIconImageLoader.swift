import AppKit
import AppContainerScanningService
import Foundation
import ImageIO
import SimControlDomain

struct AppIconImageLoader {
  struct Request: Hashable {
    let iconPath: URL?
    let appBundlePath: URL?
    let bundleID: String
    let displayName: String
    let platform: SimulatorPlatform?
    let deviceTypeID: String?

    var cacheKey: NSString {
      [
        iconPath?.path ?? "",
        appBundlePath?.path ?? "",
        bundleID,
        displayName,
        platform?.rawValue ?? "",
        deviceTypeID ?? ""
      ]
      .joined(separator: "|") as NSString
    }
  }

  static let shared = AppIconImageLoader()

  private static let targetPixelSize = 96

  private let cache: NSCache<NSString, NSImage>
  private let loadImage: (Request) async -> NSImage?

  init(
    cache: NSCache<NSString, NSImage> = NSCache<NSString, NSImage>(),
    loadImage: @escaping (Request) async -> NSImage? = AppIconImageLoader.loadImage
  ) {
    cache.countLimit = 256
    self.cache = cache
    self.loadImage = loadImage
  }

  func image(for iconPath: URL?) async -> NSImage? {
    await image(for: Request(
      iconPath: iconPath,
      appBundlePath: nil,
      bundleID: "",
      displayName: "",
      platform: nil,
      deviceTypeID: nil
    ))
  }

  func image(for request: Request) async -> NSImage? {
    guard request.iconPath != nil || request.appBundlePath != nil else {
      return nil
    }
    return await imageFromRequest(request)
  }

  private func imageFromRequest(_ request: Request) async -> NSImage? {
    if let cachedImage = cache.object(forKey: request.cacheKey) {
      return cachedImage
    }

    guard let image = await loadImage(request) else {
      return nil
    }

    cache.setObject(image, forKey: request.cacheKey)
    return image
  }

  private static func loadImage(for request: Request) async -> NSImage? {
    await Task.detached(priority: .utility) {
      if let iconPath = request.iconPath,
         let image = downsampledImage(from: iconPath) ?? NSImage(contentsOf: iconPath) {
        return image
      }

      guard let appBundlePath = request.appBundlePath,
            let iconPath = AppIconAssetResolver().iconPath(
              in: appBundlePath,
              platform: request.platform,
              deviceTypeID: request.deviceTypeID,
              bundleID: request.bundleID,
              displayName: request.displayName
            )
      else {
        return nil
      }
      return downsampledImage(from: iconPath) ?? NSImage(contentsOf: iconPath)
    }.value
  }

  private static func downsampledImage(from iconPath: URL) -> NSImage? {
    let sourceOptions: [CFString: Any] = [
      kCGImageSourceShouldCache: false
    ]
    guard let source = CGImageSourceCreateWithURL(iconPath as CFURL, sourceOptions as CFDictionary) else {
      return nil
    }

    let thumbnailOptions: [CFString: Any] = [
      kCGImageSourceCreateThumbnailFromImageAlways: true,
      kCGImageSourceCreateThumbnailWithTransform: true,
      kCGImageSourceShouldCacheImmediately: true,
      kCGImageSourceThumbnailMaxPixelSize: targetPixelSize
    ]
    guard let cgImage = CGImageSourceCreateThumbnailAtIndex(source, 0, thumbnailOptions as CFDictionary) else {
      return nil
    }

    return NSImage(
      cgImage: cgImage,
      size: NSSize(width: cgImage.width, height: cgImage.height)
    )
  }
}
