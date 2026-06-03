import Foundation

extension SimulatorPlatform {
  var inventoryTitle: String {
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
}

extension SimulatorDevice.State {
  var inventoryTitle: String {
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
}
