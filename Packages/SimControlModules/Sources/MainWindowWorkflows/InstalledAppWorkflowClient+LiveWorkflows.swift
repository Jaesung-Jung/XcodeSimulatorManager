import Foundation
import SimControlClients
import SimControlDomain

func runLaunchAppWorkflow(
  deviceID: SimulatorDevice.ID,
  appID: InstalledApp.ID,
  bundleID: String,
  deviceState: SimulatorDevice.State,
  coreSimulatorService: CoreSimulatorClient,
  simulatorRepository: SimulatorRepositoryClient
) async -> InstalledAppWorkflowResult {
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
}

func runTerminateAppWorkflow(
  deviceID: SimulatorDevice.ID,
  appID: InstalledApp.ID,
  bundleID: String,
  coreSimulatorService: CoreSimulatorClient,
  simulatorRepository: SimulatorRepositoryClient
) async -> InstalledAppWorkflowResult {
  await refreshAppCommandResult(
    commandResults: [
      await coreSimulatorService.terminateApp(deviceID, bundleID)
    ],
    simulatorRepository: simulatorRepository,
    preferredSelectedDeviceID: deviceID,
    preferredSelectedAppID: appID
  )
}

func runUninstallAppWorkflow(
  deviceID: SimulatorDevice.ID,
  appID: InstalledApp.ID,
  bundleID: String,
  coreSimulatorService: CoreSimulatorClient,
  simulatorRepository: SimulatorRepositoryClient
) async -> InstalledAppWorkflowResult {
  let uninstallResult = await coreSimulatorService.uninstallApp(deviceID, bundleID)
  return await refreshAppCommandResult(
    commandResults: [uninstallResult],
    simulatorRepository: simulatorRepository,
    preferredSelectedDeviceID: deviceID,
    preferredSelectedAppID: uninstallResult.succeeded ? nil : appID
  )
}

func runResetSandboxWorkflow(
  deviceID: SimulatorDevice.ID,
  appID: InstalledApp.ID,
  dataContainer: URL,
  appSandboxReset: AppSandboxResetClient,
  simulatorRepository: SimulatorRepositoryClient
) async -> InstalledAppWorkflowResult {
  await refreshAppCommandResult(
    commandResults: [
      await appSandboxReset.resetSandbox(dataContainer)
    ],
    simulatorRepository: simulatorRepository,
    preferredSelectedDeviceID: deviceID,
    preferredSelectedAppID: appID
  )
}

func runInstallAppOnSimulator(
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

func refreshAppCommandResult(
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
