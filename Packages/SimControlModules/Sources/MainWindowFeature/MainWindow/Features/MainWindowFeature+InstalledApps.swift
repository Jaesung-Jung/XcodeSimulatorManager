import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature Installed Apps

extension MainWindowFeature {
  func runLaunchAppCommand(
    _ state: inout State,
    appID: String
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: appID, in: state),
          canLaunchApp(context.app, on: context.device)
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .launch,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, appSandboxReset, simulatorRepository] send in
      let workflow = InstalledAppWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        appSandboxReset: appSandboxReset,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.launchApp(
        context.device.id,
        context.app.id,
        context.app.bundleID,
        context.device.state
      )
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          result.commandResults,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )

      await send(
        .appCommandRefreshResponse(
          appCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )
    }
  }

  func runTerminateAppCommand(
    _ state: inout State,
    appID: String
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: appID, in: state),
          canTerminateApp(context.app, on: context.device)
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .terminate,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, appSandboxReset, simulatorRepository] send in
      let workflow = InstalledAppWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        appSandboxReset: appSandboxReset,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.terminateApp(
        context.device.id,
        context.app.id,
        context.app.bundleID
      )
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          result.commandResults,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )

      await send(
        .appCommandRefreshResponse(
          appCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )
    }
  }

  func runUninstallAppCommand(
    _ state: inout State,
    confirmationState: AppDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: confirmationState.appID, in: state),
          canUninstallApp(context.app, on: context.device),
          appDestructiveConfirmationState(
            appID: confirmationState.appID,
            in: state,
            includesDataContainer: false
          ) == confirmationState
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .uninstall,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, appSandboxReset, simulatorRepository] send in
      let workflow = InstalledAppWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        appSandboxReset: appSandboxReset,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.uninstallApp(
        context.device.id,
        context.app.id,
        context.app.bundleID
      )
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          result.commandResults,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )

      await send(
        .appCommandRefreshResponse(
          appCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )
    }
  }

  func runResetAppSandboxCommand(
    _ state: inout State,
    confirmationState: AppDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: confirmationState.appID, in: state),
          let dataContainer = context.app.dataContainer,
          appDestructiveConfirmationState(
            appID: confirmationState.appID,
            in: state,
            includesDataContainer: true
          ) == confirmationState
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .resetSandbox,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, appSandboxReset, simulatorRepository] send in
      let workflow = InstalledAppWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        appSandboxReset: appSandboxReset,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.resetSandbox(
        context.device.id,
        context.app.id,
        dataContainer
      )
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          result.commandResults,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )

      await send(
        .appCommandRefreshResponse(
          appCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )
    }
  }

  func runInstallAppOnSimulatorCommand(
    _ state: inout State,
    formState: InstallAppTargetFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: formState.sourceAppID, in: state),
          let appBundlePath = context.app.appBundlePath,
          appBundlePath == formState.appBundlePath,
          context.app.bundleID == formState.bundleID,
          context.device.id == formState.sourceDeviceID,
          let targetDevice = installTargetDevice(id: formState.targetDeviceID, sourceDevice: context.device, in: state)
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .installOnSimulator,
      sourceDeviceID: context.device.id,
      appID: context.app.id,
      targetDeviceID: targetDevice.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, appSandboxReset, simulatorRepository] send in
      let workflow = InstalledAppWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        appSandboxReset: appSandboxReset,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.installAppOnSimulator(
        InstallAppOnSimulatorWorkflowRequest(
          targetDeviceID: targetDevice.id,
          targetDeviceState: targetDevice.state,
          bundleID: context.app.bundleID,
          appBundlePath: appBundlePath,
          launchAfterInstall: formState.launchAfterInstall
        )
      )
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          result.commandResults,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )

      await send(
        .appCommandRefreshResponse(
          appCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID,
          preferredSelectedAppID: result.preferredSelectedAppID
        )
      )
    }
  }
}
