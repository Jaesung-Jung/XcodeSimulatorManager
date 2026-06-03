import Foundation
import SimControlDomain

/// A TCA dependency boundary for CoreSimulator command operations.
public struct CoreSimulatorClient: Sendable {
  public var openSimulatorApp: @Sendable () async -> CommandResult
  public var bootDevice: @Sendable (_ id: String) async -> CommandResult
  public var bootDeviceIfNeeded: @Sendable (_ id: String) async -> CommandResult
  public var shutdownDevice: @Sendable (_ id: String) async -> CommandResult
  public var createDevice: @Sendable (_ name: String, _ deviceTypeID: String, _ runtimeID: String) async -> CommandResult
  public var cloneDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult
  public var renameDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult
  public var eraseDevice: @Sendable (_ id: String) async -> CommandResult
  public var deleteDevice: @Sendable (_ id: String) async -> CommandResult
  public var pairDevices: @Sendable (_ watchDeviceID: String, _ phoneDeviceID: String) async -> CommandResult
  public var unpairDevice: @Sendable (_ pairID: String) async -> CommandResult
  public var launchApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult
  public var terminateApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult
  public var uninstallApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult
  public var installApp: @Sendable (_ deviceID: String, _ appBundlePath: URL) async -> CommandResult
  public var getAppContainer: @Sendable (
    _ deviceID: String,
    _ bundleID: String,
    _ container: SimulatorAppContainerKind
  ) async -> CommandResult
  public var openURL: @Sendable (_ deviceID: String, _ urlString: String) async -> CommandResult
  public var pushNotification: @Sendable (_ deviceID: String, _ bundleID: String?, _ payloadJSON: String) async -> CommandResult
  public var setPrivacyPermission: @Sendable (_ deviceID: String, _ action: String, _ service: String, _ bundleID: String?) async -> CommandResult
  public var setLocation: @Sendable (_ deviceID: String, _ coordinate: String) async -> CommandResult
  public var clearLocation: @Sendable (_ deviceID: String) async -> CommandResult
  public var setStatusBarOverride: @Sendable (_ deviceID: String, _ arguments: [String]) async -> CommandResult
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
    getAppContainer: @escaping @Sendable (
      _ deviceID: String,
      _ bundleID: String,
      _ container: SimulatorAppContainerKind
    ) async -> CommandResult,
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
