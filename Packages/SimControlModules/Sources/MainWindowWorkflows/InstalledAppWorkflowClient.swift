import Foundation
import SimControlClients
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
        var commandResults: [CommandResult] = []

        if deviceState == .shutdown {
          let bootResult = await coreSimulatorService.bootDeviceIfNeeded(deviceID)
          commandResults.append(bootResult)

          guard bootResult.succeeded else {
            return await refreshAppCommandResult(
              commandResults: commandResults,
              simulatorRepository: simulatorRepository,
              preferredSelectedDeviceID: deviceID,
              preferredSelectedAppID: appID
            )
          }
        }

        commandResults.append(
          await coreSimulatorService.launchApp(deviceID, bundleID)
        )
        return await refreshAppCommandResult(
          commandResults: commandResults,
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: deviceID,
          preferredSelectedAppID: appID
        )
      },
      terminateApp: { deviceID, appID, bundleID in
        await refreshAppCommandResult(
          commandResults: [
            await coreSimulatorService.terminateApp(deviceID, bundleID)
          ],
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: deviceID,
          preferredSelectedAppID: appID
        )
      },
      uninstallApp: { deviceID, appID, bundleID in
        let uninstallResult = await coreSimulatorService.uninstallApp(
          deviceID,
          bundleID
        )
        return await refreshAppCommandResult(
          commandResults: [uninstallResult],
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: deviceID,
          preferredSelectedAppID: uninstallResult.succeeded ? nil : appID
        )
      },
      resetSandbox: { deviceID, appID, dataContainer in
        await refreshAppCommandResult(
          commandResults: [
            await appSandboxReset.resetSandbox(dataContainer)
          ],
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: deviceID,
          preferredSelectedAppID: appID
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

private func runInstallAppOnSimulator(
  _ request: InstallAppOnSimulatorWorkflowRequest,
  coreSimulatorService: CoreSimulatorClient,
  simulatorRepository: SimulatorRepositoryClient
) async -> InstalledAppWorkflowResult {
  var commandResults: [CommandResult] = []
  var installed = false

  if request.targetDeviceState == .shutdown {
    let bootResult = await coreSimulatorService.bootDeviceIfNeeded(
      request.targetDeviceID
    )
    commandResults.append(bootResult)

    guard bootResult.succeeded else {
      return await refreshAppCommandResult(
        commandResults: commandResults,
        simulatorRepository: simulatorRepository,
        preferredSelectedDeviceID: nil,
        preferredSelectedAppID: nil
      )
    }
  }

  let installResult = await coreSimulatorService.installApp(
    request.targetDeviceID,
    request.appBundlePath
  )
  commandResults.append(installResult)
  installed = installResult.succeeded

  if installed && request.launchAfterInstall {
    commandResults.append(
      await coreSimulatorService.launchApp(
        request.targetDeviceID,
        request.bundleID
      )
    )
  }

  let preferredSelectedDeviceID = installed ? request.targetDeviceID : nil
  let preferredSelectedAppID = installed
    ? "\(request.targetDeviceID):\(request.bundleID)"
    : nil

  return await refreshAppCommandResult(
    commandResults: commandResults,
    simulatorRepository: simulatorRepository,
    preferredSelectedDeviceID: preferredSelectedDeviceID,
    preferredSelectedAppID: preferredSelectedAppID
  )
}

private func refreshAppCommandResult(
  commandResults: [CommandResult],
  simulatorRepository: SimulatorRepositoryClient,
  preferredSelectedDeviceID: SimulatorDevice.ID?,
  preferredSelectedAppID: InstalledApp.ID?
) async -> InstalledAppWorkflowResult {
  InstalledAppWorkflowResult(
    commandResults: commandResults,
    refreshResult: await simulatorRepository.refresh(),
    preferredSelectedDeviceID: preferredSelectedDeviceID,
    preferredSelectedAppID: preferredSelectedAppID
  )
}
