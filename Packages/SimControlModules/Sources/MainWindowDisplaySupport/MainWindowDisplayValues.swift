import SimControlDomain
import SwiftUI

extension SimulatorPlatform {
  public var displayTitle: String {
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

  public var symbolName: String {
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
  public var symbolName: String {
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
  public var displayTitle: String {
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

  public var statusTint: Color {
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
