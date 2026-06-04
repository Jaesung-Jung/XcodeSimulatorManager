import Foundation
import SimControlDomain

struct MainWindowAppCall: Equatable {
  let deviceID: String
  let bundleID: String
}

struct MainWindowInstallAppCall: Equatable {
  let deviceID: String
  let appBundlePath: URL
}

actor MainWindowAppCommandRecorder {
  private let bootResult: CommandResult
  private let launchResult: CommandResult
  private let terminateResult: CommandResult
  private let uninstallResult: CommandResult
  private let installResult: CommandResult
  private var recordedBootCalls: [String] = []
  private var recordedLaunchCalls: [MainWindowAppCall] = []
  private var recordedTerminateCalls: [MainWindowAppCall] = []
  private var recordedUninstallCalls: [MainWindowAppCall] = []
  private var recordedInstallCalls: [MainWindowInstallAppCall] = []

  init(
    bootResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "bootstatus",
      arguments: ["simctl", "bootstatus", "DEVICE", "-b"]
    ),
    launchResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "launch-app",
      arguments: ["simctl", "launch", "DEVICE", "com.example.app"]
    ),
    terminateResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "terminate-app",
      arguments: ["simctl", "terminate", "DEVICE", "com.example.app"]
    ),
    uninstallResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "uninstall-app",
      arguments: ["simctl", "uninstall", "DEVICE", "com.example.app"]
    ),
    installResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "install-app",
      arguments: ["simctl", "install", "DEVICE", "/tmp/Example.app"]
    )
  ) {
    self.bootResult = bootResult
    self.launchResult = launchResult
    self.terminateResult = terminateResult
    self.uninstallResult = uninstallResult
    self.installResult = installResult
  }

  func bootDeviceIfNeeded(id: String) -> CommandResult {
    recordedBootCalls.append(id)
    return bootResult
  }

  func launchApp(deviceID: String, bundleID: String) -> CommandResult {
    recordedLaunchCalls.append(
      MainWindowAppCall(deviceID: deviceID, bundleID: bundleID)
    )
    return launchResult
  }

  func terminateApp(deviceID: String, bundleID: String) -> CommandResult {
    recordedTerminateCalls.append(
      MainWindowAppCall(deviceID: deviceID, bundleID: bundleID)
    )
    return terminateResult
  }

  func uninstallApp(deviceID: String, bundleID: String) -> CommandResult {
    recordedUninstallCalls.append(
      MainWindowAppCall(deviceID: deviceID, bundleID: bundleID)
    )
    return uninstallResult
  }

  func installApp(deviceID: String, appBundlePath: URL) -> CommandResult {
    recordedInstallCalls.append(
      MainWindowInstallAppCall(deviceID: deviceID, appBundlePath: appBundlePath)
    )
    return installResult
  }

  func bootCalls() -> [String] {
    recordedBootCalls
  }

  func launchCalls() -> [MainWindowAppCall] {
    recordedLaunchCalls
  }

  func terminateCalls() -> [MainWindowAppCall] {
    recordedTerminateCalls
  }

  func uninstallCalls() -> [MainWindowAppCall] {
    recordedUninstallCalls
  }

  func installCalls() -> [MainWindowInstallAppCall] {
    recordedInstallCalls
  }
}
