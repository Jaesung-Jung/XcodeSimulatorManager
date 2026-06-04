import Foundation
import SimControlDomain

extension SimulatorRepository {
  func simulatorPlatform(from rawPlatform: String?) -> SimulatorPlatform {
    switch normalized(rawPlatform) {
    case "ios", "iphonesimulator", "comappleplatformiphonesimulator":
      return .iOS
    case "watchos", "watchsimulator", "comappleplatformwatchsimulator":
      return .watchOS
    case "tvos", "appletvsimulator", "comappleplatformappletvsimulator":
      return .tvOS
    case "visionos", "xros", "xrsimulator", "comappleplatformxrsimulator":
      return .visionOS
    default:
      return .unknown
    }
  }

  func deviceState(from rawState: String?) -> SimulatorDevice.State {
    switch normalized(rawState) {
    case "creating":
      return .creating
    case "shutdown":
      return .shutdown
    case "booting":
      return .booting
    case "booted":
      return .booted
    case "shuttingdown":
      return .shuttingDown
    default:
      return .unknown
    }
  }

  func pairState(from rawState: String?) -> DevicePair.State {
    switch normalized(rawState) {
    case "active":
      return .active
    case "inactive":
      return .inactive
    case "unavailable":
      return .unavailable
    default:
      return .unknown
    }
  }

  func displayName(_ value: String?, fallback: String) -> String {
    nonEmpty(value) ?? fallback
  }

  func nonEmpty(_ value: String?) -> String? {
    guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmedValue.isEmpty
    else {
      return nil
    }

    return trimmedValue
  }

  func normalized(_ value: String?) -> String {
    nonEmpty(value)?
      .lowercased()
      .filter(\.isLetter) ?? ""
  }

  func fileURL(from path: String?) -> URL? {
    guard let path = nonEmpty(path) else {
      return nil
    }

    return URL(fileURLWithPath: path)
  }

  func date(from value: String?) -> Date? {
    guard let value = nonEmpty(value) else {
      return nil
    }

    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: value) {
      return date
    }

    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: value)
  }
}
