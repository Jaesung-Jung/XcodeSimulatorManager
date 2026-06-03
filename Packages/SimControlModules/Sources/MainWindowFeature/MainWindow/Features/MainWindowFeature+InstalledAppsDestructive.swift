import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows

// MARK: - MainWindowFeature Installed App Destructive Commands

extension MainWindowFeature {
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
}
