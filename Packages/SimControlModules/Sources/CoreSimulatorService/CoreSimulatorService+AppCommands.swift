import Foundation
import SimControlDomain

extension CoreSimulatorService {
  /// Launches an installed app on a simulator device.
  public func launchApp(deviceID: String, bundleID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "launch", deviceID, bundleID], deviceCommandTimeout)
  }

  /// Terminates an installed app on a simulator device.
  public func terminateApp(deviceID: String, bundleID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "terminate", deviceID, bundleID], deviceCommandTimeout)
  }

  /// Uninstalls an app from a simulator device.
  public func uninstallApp(deviceID: String, bundleID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "uninstall", deviceID, bundleID], deviceCommandTimeout)
  }

  /// Installs an app bundle on a simulator device.
  public func installApp(deviceID: String, appBundlePath: URL) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "install", deviceID, appBundlePath.path], deviceCommandTimeout)
  }

  /// Resolves an app container path through `simctl`.
  public func getAppContainer(deviceID: String, bundleID: String, container: SimulatorAppContainerKind) async -> CommandResult {
    await runCommand(
      "xcrun",
      [
        "simctl",
        "get_app_container",
        deviceID,
        bundleID,
        container.simctlArgument
      ],
      deviceCommandTimeout
    )
  }
}
