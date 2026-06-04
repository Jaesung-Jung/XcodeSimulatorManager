import AppKit
import Foundation
import ImageIO

struct AppIconImageLoader {
  static let shared = AppIconImageLoader()

  private static let targetPixelSize = 96

  private let cache: NSCache<NSURL, NSImage>
  private let loadImage: (URL) async -> NSImage?

  init(
    cache: NSCache<NSURL, NSImage> = NSCache<NSURL, NSImage>(),
    loadImage: @escaping (URL) async -> NSImage? = AppIconImageLoader.loadImage
  ) {
    cache.countLimit = 256
    self.cache = cache
    self.loadImage = loadImage
  }

  func image(for iconPath: URL?) async -> NSImage? {
    guard let iconPath else {
      return nil
    }

    let cacheKey = iconPath as NSURL
    if let cachedImage = cache.object(forKey: cacheKey) {
      return cachedImage
    }

    guard let image = await loadImage(iconPath) else {
      return nil
    }

    cache.setObject(image, forKey: cacheKey)
    return image
  }

  private static func loadImage(from iconPath: URL) async -> NSImage? {
    await Task.detached(priority: .utility) {
      downsampledImage(from: iconPath) ?? NSImage(contentsOf: iconPath)
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
