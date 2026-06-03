import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows

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

    return .run { [installedAppWorkflow] send in
      let result = await installedAppWorkflow.launchApp(
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

    return .run { [installedAppWorkflow] send in
      let result = await installedAppWorkflow.terminateApp(
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
}
