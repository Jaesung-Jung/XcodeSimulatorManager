import Foundation
import SwiftUI

extension SimulatorPlatform {
  var displayTitle: String {
    switch self {
    case .iOS:
      "iOS"
    case .watchOS:
      "watchOS"
    case .tvOS:
      "tvOS"
    case .visionOS:
      "visionOS"
    case .unknown:
      "Unknown"
    }
  }

  var symbolName: String {
    switch self {
    case .iOS:
      "iphone"
    case .watchOS:
      "applewatch"
    case .tvOS:
      "appletv"
    case .visionOS:
      "visionpro"
    case .unknown:
      "display"
    }
  }
}

extension SimulatorDevice.State {
  var displayTitle: String {
    switch self {
    case .creating:
      "Creating"
    case .shutdown:
      "Shutdown"
    case .booting:
      "Booting"
    case .booted:
      "Booted"
    case .shuttingDown:
      "Shutting Down"
    case .unknown:
      "Unknown"
    }
  }

  var statusTint: Color {
    switch self {
    case .booted:
      .green
    case .booting, .creating, .shuttingDown:
      .orange
    case .shutdown:
      .secondary
    case .unknown:
      .red
    }
  }
}

extension SimulatorWarning.Severity {
  var displayTitle: String {
    switch self {
    case .info:
      "Info"
    case .warning:
      "Warning"
    case .error:
      "Error"
    }
  }

  var badgeTint: Color {
    switch self {
    case .info:
      .blue
    case .warning:
      .orange
    case .error:
      .red
    }
  }
}

extension SimulatorDevice {
  var availabilityTitle: String {
    isAvailable ? "Available" : "Unavailable"
  }

  var dataPathSizeTitle: String {
    guard let dataPathSize else {
      return "Unknown"
    }

    return ByteCountFormatter.string(fromByteCount: dataPathSize, countStyle: .file)
  }
}

extension CommandResult {
  var commandLineSummary: String {
    let executableName = URL(fileURLWithPath: executable).lastPathComponent
    return ([executableName] + arguments).joined(separator: " ")
  }

  var durationTitle: String {
    String(format: "%.2fs", duration)
  }
}
