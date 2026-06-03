import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows

// MARK: - MainWindowFeature Installed App Installation Commands

extension MainWindowFeature {
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
