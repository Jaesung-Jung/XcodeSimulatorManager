import Foundation
import SimControlDomain

/// A TCA dependency boundary for CoreSimulator command operations.
public struct CoreSimulatorClient: Sendable {
  /// Opens Simulator.app.
  public var openSimulatorApp: @Sendable () async -> CommandResult

  /// Boots a simulator device.
  public var bootDevice: @Sendable (_ id: String) async -> CommandResult

  /// Boots a simulator device if needed and waits for boot completion.
  public var bootDeviceIfNeeded: @Sendable (_ id: String) async -> CommandResult

  /// Shuts down a simulator device.
  public var shutdownDevice: @Sendable (_ id: String) async -> CommandResult

  /// Creates a simulator device.
  public var createDevice: @Sendable (_ name: String, _ deviceTypeID: String, _ runtimeID: String) async -> CommandResult

  /// Clones a simulator device.
  public var cloneDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult

  /// Renames a simulator device.
  public var renameDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult

  /// Erases a simulator device.
  public var eraseDevice: @Sendable (_ id: String) async -> CommandResult

  /// Deletes a simulator device.
  public var deleteDevice: @Sendable (_ id: String) async -> CommandResult

  /// Pairs a watch simulator with a phone simulator.
  public var pairDevices: @Sendable (_ watchDeviceID: String, _ phoneDeviceID: String) async -> CommandResult

  /// Removes a simulator pair.
  public var unpairDevice: @Sendable (_ pairID: String) async -> CommandResult

  /// Launches an installed app on a simulator device.
  public var launchApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult

  /// Terminates an installed app on a simulator device.
  public var terminateApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult

  /// Uninstalls an app from a simulator device.
  public var uninstallApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult

  /// Installs an app bundle on a simulator device.
  public var installApp: @Sendable (_ deviceID: String, _ appBundlePath: URL) async -> CommandResult

  /// Resolves an app container path through `simctl`.
  public var getAppContainer: @Sendable (_ deviceID: String, _ bundleID: String, _ container: SimulatorAppContainerKind) async -> CommandResult

  /// Opens a URL in a simulator device.
  public var openURL: @Sendable (_ deviceID: String, _ urlString: String) async -> CommandResult

  /// Sends a remote notification payload to a simulator device.
  public var pushNotification: @Sendable (_ deviceID: String, _ bundleID: String?, _ payloadJSON: String) async -> CommandResult

  /// Sets a simulator privacy permission.
  public var setPrivacyPermission: @Sendable (_ deviceID: String, _ action: String, _ service: String, _ bundleID: String?) async -> CommandResult

  /// Sets the simulator location.
  public var setLocation: @Sendable (_ deviceID: String, _ coordinate: String) async -> CommandResult

  /// Clears the simulator location override.
  public var clearLocation: @Sendable (_ deviceID: String) async -> CommandResult

  /// Sets simulator status bar override arguments.
  public var setStatusBarOverride: @Sendable (_ deviceID: String, _ arguments: [String]) async -> CommandResult

  /// Clears simulator status bar overrides.
  public var clearStatusBarOverride: @Sendable (_ deviceID: String) async -> CommandResult

  /// Creates a simulator command client from endpoint closures.
  public init(
    openSimulatorApp: @escaping @Sendable () async -> CommandResult,
    bootDevice: @escaping @Sendable (_ id: String) async -> CommandResult,
    bootDeviceIfNeeded: @escaping @Sendable (_ id: String) async -> CommandResult,
    shutdownDevice: @escaping @Sendable (_ id: String) async -> CommandResult,
    createDevice: @escaping @Sendable (_ name: String, _ deviceTypeID: String, _ runtimeID: String) async -> CommandResult,
    cloneDevice: @escaping @Sendable (_ id: String, _ name: String) async -> CommandResult,
    renameDevice: @escaping @Sendable (_ id: String, _ name: String) async -> CommandResult,
    eraseDevice: @escaping @Sendable (_ id: String) async -> CommandResult,
    deleteDevice: @escaping @Sendable (_ id: String) async -> CommandResult,
    pairDevices: @escaping @Sendable (_ watchDeviceID: String, _ phoneDeviceID: String) async -> CommandResult,
    unpairDevice: @escaping @Sendable (_ pairID: String) async -> CommandResult,
    launchApp: @escaping @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult,
    terminateApp: @escaping @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult,
    uninstallApp: @escaping @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult,
    installApp: @escaping @Sendable (_ deviceID: String, _ appBundlePath: URL) async -> CommandResult,
    getAppContainer: @escaping @Sendable (_ deviceID: String, _ bundleID: String, _ container: SimulatorAppContainerKind) async -> CommandResult,
    openURL: @escaping @Sendable (_ deviceID: String, _ urlString: String) async -> CommandResult,
    pushNotification: @escaping @Sendable (_ deviceID: String, _ bundleID: String?, _ payloadJSON: String) async -> CommandResult,
    setPrivacyPermission: @escaping @Sendable (_ deviceID: String, _ action: String, _ service: String, _ bundleID: String?) async -> CommandResult,
    setLocation: @escaping @Sendable (_ deviceID: String, _ coordinate: String) async -> CommandResult,
    clearLocation: @escaping @Sendable (_ deviceID: String) async -> CommandResult,
    setStatusBarOverride: @escaping @Sendable (_ deviceID: String, _ arguments: [String]) async -> CommandResult,
    clearStatusBarOverride: @escaping @Sendable (_ deviceID: String) async -> CommandResult
  ) {
    self.openSimulatorApp = openSimulatorApp
    self.bootDevice = bootDevice
    self.bootDeviceIfNeeded = bootDeviceIfNeeded
    self.shutdownDevice = shutdownDevice
    self.createDevice = createDevice
    self.cloneDevice = cloneDevice
    self.renameDevice = renameDevice
    self.eraseDevice = eraseDevice
    self.deleteDevice = deleteDevice
    self.pairDevices = pairDevices
    self.unpairDevice = unpairDevice
    self.launchApp = launchApp
    self.terminateApp = terminateApp
    self.uninstallApp = uninstallApp
    self.installApp = installApp
    self.getAppContainer = getAppContainer
    self.openURL = openURL
    self.pushNotification = pushNotification
    self.setPrivacyPermission = setPrivacyPermission
    self.setLocation = setLocation
    self.clearLocation = clearLocation
    self.setStatusBarOverride = setStatusBarOverride
    self.clearStatusBarOverride = clearStatusBarOverride
  }
}
