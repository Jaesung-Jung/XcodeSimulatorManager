import Dependencies

extension CoreSimulatorClient: TestDependencyKey {
  /// An unimplemented client used by dependency tests unless overridden.
  public static let testValue = CoreSimulatorClient(
    openSimulatorApp: unimplemented(
      "CoreSimulatorClient.openSimulatorApp",
      placeholder: placeholderCommandResult("CoreSimulatorClient.openSimulatorApp")
    ),
    bootDevice: unimplemented(
      "CoreSimulatorClient.bootDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.bootDevice")
    ),
    bootDeviceIfNeeded: unimplemented(
      "CoreSimulatorClient.bootDeviceIfNeeded",
      placeholder: placeholderCommandResult("CoreSimulatorClient.bootDeviceIfNeeded")
    ),
    shutdownDevice: unimplemented(
      "CoreSimulatorClient.shutdownDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.shutdownDevice")
    ),
    createDevice: unimplemented(
      "CoreSimulatorClient.createDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.createDevice")
    ),
    cloneDevice: unimplemented(
      "CoreSimulatorClient.cloneDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.cloneDevice")
    ),
    renameDevice: unimplemented(
      "CoreSimulatorClient.renameDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.renameDevice")
    ),
    eraseDevice: unimplemented(
      "CoreSimulatorClient.eraseDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.eraseDevice")
    ),
    deleteDevice: unimplemented(
      "CoreSimulatorClient.deleteDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.deleteDevice")
    ),
    pairDevices: unimplemented(
      "CoreSimulatorClient.pairDevices",
      placeholder: placeholderCommandResult("CoreSimulatorClient.pairDevices")
    ),
    unpairDevice: unimplemented(
      "CoreSimulatorClient.unpairDevice",
      placeholder: placeholderCommandResult("CoreSimulatorClient.unpairDevice")
    ),
    launchApp: unimplemented(
      "CoreSimulatorClient.launchApp",
      placeholder: placeholderCommandResult("CoreSimulatorClient.launchApp")
    ),
    terminateApp: unimplemented(
      "CoreSimulatorClient.terminateApp",
      placeholder: placeholderCommandResult("CoreSimulatorClient.terminateApp")
    ),
    uninstallApp: unimplemented(
      "CoreSimulatorClient.uninstallApp",
      placeholder: placeholderCommandResult("CoreSimulatorClient.uninstallApp")
    ),
    installApp: unimplemented(
      "CoreSimulatorClient.installApp",
      placeholder: placeholderCommandResult("CoreSimulatorClient.installApp")
    ),
    getAppContainer: unimplemented(
      "CoreSimulatorClient.getAppContainer",
      placeholder: placeholderCommandResult("CoreSimulatorClient.getAppContainer")
    ),
    openURL: unimplemented(
      "CoreSimulatorClient.openURL",
      placeholder: placeholderCommandResult("CoreSimulatorClient.openURL")
    ),
    pushNotification: unimplemented(
      "CoreSimulatorClient.pushNotification",
      placeholder: placeholderCommandResult("CoreSimulatorClient.pushNotification")
    ),
    setPrivacyPermission: unimplemented(
      "CoreSimulatorClient.setPrivacyPermission",
      placeholder: placeholderCommandResult("CoreSimulatorClient.setPrivacyPermission")
    ),
    setLocation: unimplemented(
      "CoreSimulatorClient.setLocation",
      placeholder: placeholderCommandResult("CoreSimulatorClient.setLocation")
    ),
    clearLocation: unimplemented(
      "CoreSimulatorClient.clearLocation",
      placeholder: placeholderCommandResult("CoreSimulatorClient.clearLocation")
    ),
    setStatusBarOverride: unimplemented(
      "CoreSimulatorClient.setStatusBarOverride",
      placeholder: placeholderCommandResult("CoreSimulatorClient.setStatusBarOverride")
    ),
    clearStatusBarOverride: unimplemented(
      "CoreSimulatorClient.clearStatusBarOverride",
      placeholder: placeholderCommandResult("CoreSimulatorClient.clearStatusBarOverride")
    )
  )
}

extension DependencyValues {
  /// The injected CoreSimulator command client.
  public var coreSimulatorService: CoreSimulatorClient {
    get { self[CoreSimulatorClient.self] }
    set { self[CoreSimulatorClient.self] = newValue }
  }
}
