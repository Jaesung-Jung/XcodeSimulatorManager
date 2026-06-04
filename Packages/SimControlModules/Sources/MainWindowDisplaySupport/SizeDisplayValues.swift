import Foundation
import SimControlDomain

extension SimulatorDevice {
  public var availabilityTitle: String { isAvailable ? "Available" : "Unavailable" }

  public var dataPathSizeTitle: String {
    guard let dataPathSize else {
      return "Unknown"
    }

    return ByteCountFormatter.string(fromByteCount: dataPathSize, countStyle: .file)
  }
}

extension InstalledApp {
  public var dataContainerSizeTitle: String {
    guard let dataContainerSize else {
      return "Unknown"
    }

    return ByteCountFormatter.string(fromByteCount: dataContainerSize, countStyle: .file)
  }
}
