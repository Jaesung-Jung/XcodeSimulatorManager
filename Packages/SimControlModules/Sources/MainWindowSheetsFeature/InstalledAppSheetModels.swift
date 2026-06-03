import Foundation
import SimControlDomain

/// Confirmation payload for destructive installed app commands.
public struct AppDestructiveConfirmationState: Equatable {
  public let appID: String
  public let appName: String
  public let bundleID: String
  public let deviceID: String
  public let deviceName: String
  public let deviceUDID: String
  public let dataContainerPath: String?

  /// Creates a confirmation payload for a destructive installed app command.
  public init(
    appID: String,
    appName: String,
    bundleID: String,
    deviceID: String,
    deviceName: String,
    deviceUDID: String,
    dataContainerPath: String?
  ) {
    self.appID = appID
    self.appName = appName
    self.bundleID = bundleID
    self.deviceID = deviceID
    self.deviceName = deviceName
    self.deviceUDID = deviceUDID
    self.dataContainerPath = dataContainerPath
  }
}

/// Candidate simulator device that can receive an app install.
public struct InstallAppTargetCandidate: Equatable, Identifiable {
  public let id: String
  public let name: String
  public let udid: String
  public let state: SimulatorDevice.State

  /// Creates an install target candidate from a simulator device.
  public init(device: SimulatorDevice) {
    self.id = device.id
    self.name = device.name
    self.udid = device.udid
    self.state = device.state
  }
}

/// Form state used to install an app bundle on another simulator.
public struct InstallAppTargetFormState: Equatable {
  public let sourceAppID: String
  public let sourceDeviceID: String
  public let appName: String
  public let bundleID: String
  public let appBundlePath: URL
  public var targetDeviceID: String
  public var launchAfterInstall: Bool

  /// Creates form state for an install-app sheet.
  public init(
    sourceAppID: String,
    sourceDeviceID: String,
    appName: String,
    bundleID: String,
    appBundlePath: URL,
    targetDeviceID: String,
    launchAfterInstall: Bool
  ) {
    self.sourceAppID = sourceAppID
    self.sourceDeviceID = sourceDeviceID
    self.appName = appName
    self.bundleID = bundleID
    self.appBundlePath = appBundlePath
    self.targetDeviceID = targetDeviceID
    self.launchAfterInstall = launchAfterInstall
  }
}
