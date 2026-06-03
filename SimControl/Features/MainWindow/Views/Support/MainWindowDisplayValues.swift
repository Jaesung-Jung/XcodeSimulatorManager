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
      "ipad.landscape.and.iphone"
    case .watchOS:
      "applewatch"
    case .tvOS:
      "appletv"
    case .visionOS:
      "vision.pro"
    case .unknown:
      "questionmark.circle.dashed"
    }
  }
}

extension SimulatorDevice {
  var symbolName: String {
    switch platform {
    case .iOS:
      name.lowercased().hasPrefix("ipad") ? "ipad.landscape" : "iphone"
    case .watchOS:
      "applewatch"
    case .tvOS:
      "appletv"
    case .visionOS:
      "vision.pro"
    case .unknown:
      "questionmark.circle.dashed"
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

extension SimulatorFilters.SidebarScope {
  var displayTitle: String {
    switch self {
    case .all:
      "All Devices"
    case .pinned:
      "Pinned"
    case .warnings:
      "Warnings"
    case .platform(let platform):
      platform.displayTitle
    case .runtime(let runtimeID):
      runtimeID
    case .state(let state):
      state.displayTitle
    }
  }
}

extension SimulatorFilters.SortDirection {
  var displayTitle: String {
    switch self {
    case .ascending:
      "Ascending"
    case .descending:
      "Descending"
    }
  }
}

extension SimulatorFilters.DeviceSort {
  var displayTitle: String {
    switch self {
    case .name:
      "Name"
    case .state:
      "State"
    case .runtime:
      "Runtime"
    case .platform:
      "Platform"
    case .lastBootedAt:
      "Last Booted"
    case .dataSize:
      "Data Size"
    }
  }
}

extension SimulatorFilters.AppSort {
  var displayTitle: String {
    switch self {
    case .name:
      "Name"
    case .bundleID:
      "Bundle ID"
    case .version:
      "Version"
    case .dataSize:
      "Data Size"
    }
  }
}

extension SimulatorFilters.AppSystemFilter {
  var displayTitle: String {
    switch self {
    case .user:
      "User Apps"
    case .system:
      "System Apps"
    case .all:
      "All Apps"
    }
  }
}

extension SimulatorFilters.PresenceFilter {
  var appGroupDisplayTitle: String {
    switch self {
    case .all:
      "Any App Groups"
    case .present:
      "Has App Groups"
    case .absent:
      "No App Groups"
    }
  }

  var databaseDisplayTitle: String {
    switch self {
    case .all:
      "Any Databases"
    case .present:
      "Has Databases"
    case .absent:
      "No Databases"
    }
  }
}

extension InstalledApp {
  var dataContainerSizeTitle: String {
    guard let dataContainerSize else {
      return "Unknown"
    }

    return ByteCountFormatter.string(fromByteCount: dataContainerSize, countStyle: .file)
  }
}
