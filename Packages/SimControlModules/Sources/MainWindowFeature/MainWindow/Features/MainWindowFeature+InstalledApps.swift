import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature.AppCommandContext

extension MainWindowFeature {
  struct AppCommandContext {
    let device: SimulatorDevice
    let app: InstalledApp
  }
}

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

    return .run { [installedAppWorkflow] send in
      let result = await installedAppWorkflow.uninstallApp(
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

    return .run { [installedAppWorkflow] send in
      let result = await installedAppWorkflow.resetSandbox(
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

    return .run { [installedAppWorkflow] send in
      let result = await installedAppWorkflow.installAppOnSimulator(
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

// MARK: - MainWindowFeature Installed App Helpers

extension MainWindowFeature {
  func appCommandContext(
    appID: String,
    in state: State
  ) -> AppCommandContext? {
    guard let selectedDevice = state.workspace.selectedDevice,
          let app = state.workspace.snapshot?.installedAppsByDeviceID[selectedDevice.id]?
            .first(where: { $0.id == appID }),
          app.deviceID == selectedDevice.id
    else {
      return nil
    }

    return AppCommandContext(device: selectedDevice, app: app)
  }

  func appDestructiveConfirmationState(
    appID: String,
    in state: State,
    includesDataContainer: Bool
  ) -> AppDestructiveConfirmationState? {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return nil
    }

    return AppDestructiveConfirmationState(
      appID: context.app.id,
      appName: context.app.displayName,
      bundleID: context.app.bundleID,
      deviceID: context.device.id,
      deviceName: context.device.name,
      deviceUDID: context.device.udid,
      dataContainerPath: includesDataContainer ? context.app.dataContainer?.path : nil
    )
  }

  func installAppTargetFormState(
    appID: String,
    in state: State
  ) -> InstallAppTargetFormState? {
    guard let context = appCommandContext(appID: appID, in: state),
          let appBundlePath = context.app.appBundlePath,
          let targetDevice = installTargetCandidates(sourceDevice: context.device, in: state).first
    else {
      return nil
    }

    return InstallAppTargetFormState(
      sourceAppID: context.app.id,
      sourceDeviceID: context.device.id,
      appName: context.app.displayName,
      bundleID: context.app.bundleID,
      appBundlePath: appBundlePath,
      targetDeviceID: targetDevice.id,
      launchAfterInstall: true
    )
  }

  func installTargetDevice(
    id: String,
    sourceDevice: SimulatorDevice,
    in state: State
  ) -> SimulatorDevice? {
    installTargetCandidates(sourceDevice: sourceDevice, in: state)
      .first { $0.id == id }
  }

  func installTargetCandidates(
    sourceDevice: SimulatorDevice,
    in state: State
  ) -> [SimulatorDevice] {
    (state.workspace.snapshot?.devices ?? []).filter { target in
      target.id != sourceDevice.id
        && target.isAvailable
        && target.platform == sourceDevice.platform
        && (target.state == .booted || target.state == .shutdown)
    }
  }

  func canLaunchApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && (device.state == .booted || device.state == .shutdown)
  }

  func canTerminateApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && device.state == .booted
  }

  func canUninstallApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && (device.state == .booted || device.state == .shutdown)
  }
}
