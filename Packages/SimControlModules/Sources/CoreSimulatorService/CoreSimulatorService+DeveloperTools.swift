import Foundation
import SimControlDomain

extension CoreSimulatorService {
  /// Opens a URL in a simulator device.
  public func openURL(deviceID: String, urlString: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "openurl", deviceID, urlString], deviceCommandTimeout)
  }

  /// Sends a remote notification payload to a simulator device.
  public func pushNotification(
    deviceID: String,
    bundleID: String?,
    payloadJSON: String
  ) async -> CommandResult {
    let payloadURL = makeRemoteNotificationPayloadURL()
    let startedAt = now()
    var arguments = ["simctl", "push", deviceID]

    if let bundleID, !bundleID.isEmpty {
      arguments.append(bundleID)
    }

    arguments.append(payloadURL.path)

    do {
      try writeRemoteNotificationPayload(payloadJSON, payloadURL)
    } catch {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Remote notification payload could not be written: \(error.localizedDescription)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    defer {
      removeRemoteNotificationPayload(payloadURL)
    }

    return await runCommand("xcrun", arguments, deviceCommandTimeout)
  }

  /// Sets a simulator privacy permission.
  public func setPrivacyPermission(deviceID: String, action: String, service: String, bundleID: String?) async -> CommandResult {
    var arguments = ["simctl", "privacy", deviceID, action, service]

    if let bundleID, !bundleID.isEmpty {
      arguments.append(bundleID)
    }

    return await runCommand("xcrun", arguments, deviceCommandTimeout)
  }

  /// Sets the simulator location.
  public func setLocation(deviceID: String, coordinate: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "location", deviceID, "set", coordinate], deviceCommandTimeout)
  }

  /// Clears the simulator location override.
  public func clearLocation(deviceID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "location", deviceID, "clear"], deviceCommandTimeout)
  }

  /// Sets simulator status bar override arguments.
  public func setStatusBarOverride(deviceID: String, arguments overrideArguments: [String]) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "status_bar", deviceID, "override"] + overrideArguments, deviceCommandTimeout)
  }

  /// Clears simulator status bar overrides.
  public func clearStatusBarOverride(deviceID: String) async -> CommandResult {
    await runCommand("xcrun", ["simctl", "status_bar", deviceID, "clear"], deviceCommandTimeout)
  }
}
