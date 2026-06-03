import Foundation
import SimControlDomain

/// The command and refresh outputs produced by an installed app workflow.
public struct InstalledAppWorkflowResult: Equatable {
  public let commandResults: [CommandResult]
  public let refreshResult: SimulatorRefreshResult
  public let preferredSelectedDeviceID: SimulatorDevice.ID?
  public let preferredSelectedAppID: InstalledApp.ID?

  /// Creates an installed app workflow result.
  public init(
    commandResults: [CommandResult],
    refreshResult: SimulatorRefreshResult,
    preferredSelectedDeviceID: SimulatorDevice.ID?,
    preferredSelectedAppID: InstalledApp.ID?
  ) {
    self.commandResults = commandResults
    self.refreshResult = refreshResult
    self.preferredSelectedDeviceID = preferredSelectedDeviceID
    self.preferredSelectedAppID = preferredSelectedAppID
  }
}

/// The input needed to install a known app bundle on another simulator.
public struct InstallAppOnSimulatorWorkflowRequest: Equatable, Sendable {
  public let targetDeviceID: SimulatorDevice.ID
  public let targetDeviceState: SimulatorDevice.State
  public let bundleID: String
  public let appBundlePath: URL
  public let launchAfterInstall: Bool

  /// Creates an install-on-simulator workflow request.
  public init(
    targetDeviceID: SimulatorDevice.ID,
    targetDeviceState: SimulatorDevice.State,
    bundleID: String,
    appBundlePath: URL,
    launchAfterInstall: Bool
  ) {
    self.targetDeviceID = targetDeviceID
    self.targetDeviceState = targetDeviceState
    self.bundleID = bundleID
    self.appBundlePath = appBundlePath
    self.launchAfterInstall = launchAfterInstall
  }
}
