import Foundation
import SimControlClients
import SimControlDomain

/// Runs installed app command sequences outside the reducer.
public struct InstalledAppWorkflowClient: Sendable {
  public var launchApp: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ appID: InstalledApp.ID,
    _ bundleID: String,
    _ deviceState: SimulatorDevice.State
  ) async -> InstalledAppWorkflowResult
  public var terminateApp: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ appID: InstalledApp.ID,
    _ bundleID: String
  ) async -> InstalledAppWorkflowResult
  public var uninstallApp: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ appID: InstalledApp.ID,
    _ bundleID: String
  ) async -> InstalledAppWorkflowResult
  public var resetSandbox: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ appID: InstalledApp.ID,
    _ dataContainer: URL
  ) async -> InstalledAppWorkflowResult
  public var installAppOnSimulator: @Sendable (
    _ request: InstallAppOnSimulatorWorkflowRequest
  ) async -> InstalledAppWorkflowResult

  /// Creates an installed app workflow from endpoint closures.
  public init(
    launchApp: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ appID: InstalledApp.ID,
      _ bundleID: String,
      _ deviceState: SimulatorDevice.State
    ) async -> InstalledAppWorkflowResult,
    terminateApp: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ appID: InstalledApp.ID,
      _ bundleID: String
    ) async -> InstalledAppWorkflowResult,
    uninstallApp: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ appID: InstalledApp.ID,
      _ bundleID: String
    ) async -> InstalledAppWorkflowResult,
    resetSandbox: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ appID: InstalledApp.ID,
      _ dataContainer: URL
    ) async -> InstalledAppWorkflowResult,
    installAppOnSimulator: @escaping @Sendable (
      _ request: InstallAppOnSimulatorWorkflowRequest
    ) async -> InstalledAppWorkflowResult
  ) {
    self.launchApp = launchApp
    self.terminateApp = terminateApp
    self.uninstallApp = uninstallApp
    self.resetSandbox = resetSandbox
    self.installAppOnSimulator = installAppOnSimulator
  }
}

public extension InstalledAppWorkflowClient {
  /// Creates an installed app workflow backed by dependency clients.
  static func live(
    coreSimulatorService: CoreSimulatorClient,
    appSandboxReset: AppSandboxResetClient,
    simulatorRepository: SimulatorRepositoryClient
  ) -> Self {
    Self(
      launchApp: { deviceID, appID, bundleID, deviceState in
        await runLaunchAppWorkflow(
          deviceID: deviceID,
          appID: appID,
          bundleID: bundleID,
          deviceState: deviceState,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        )
      },
      terminateApp: { deviceID, appID, bundleID in
        await runTerminateAppWorkflow(
          deviceID: deviceID,
          appID: appID,
          bundleID: bundleID,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        )
      },
      uninstallApp: { deviceID, appID, bundleID in
        await runUninstallAppWorkflow(
          deviceID: deviceID,
          appID: appID,
          bundleID: bundleID,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        )
      },
      resetSandbox: { deviceID, appID, dataContainer in
        await runResetSandboxWorkflow(
          deviceID: deviceID,
          appID: appID,
          dataContainer: dataContainer,
          appSandboxReset: appSandboxReset,
          simulatorRepository: simulatorRepository
        )
      },
      installAppOnSimulator: { request in
        await runInstallAppOnSimulator(
          request,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        )
      }
    )
  }
}
