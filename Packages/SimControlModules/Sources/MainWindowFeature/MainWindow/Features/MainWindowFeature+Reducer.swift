import ComposableArchitecture
import MainWindowFeatureSupport
import MenuBarFeature
import SimControlDomain
import WorkspaceFeature

// MARK: - MainWindowFeature Reducer
extension MainWindowFeature {
  func route(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case .task:
      guard state.workspace.snapshot == nil else {
        return .none
      }

      return refresh(&state)

    case .menuBar(.presented(let date)):
      return autoRefreshFromMenuBar(&state, at: date)

    case .menuBar(.refreshButtonTapped):
      return refresh(&state)

    case .menuBar(.openSimulatorAppButtonTapped):
      return openSimulatorApp(&state)

    case .menuBar(.deviceSelected(let deviceID)):
      state.workspace.selectDevice(id: deviceID)
      return .none

    case .menuBar(.appSelected(let deviceID, let appID)):
      state.workspace.selectDevice(id: deviceID)
      state.workspace.selectApp(id: appID)
      return .none

    case .refreshButtonTapped:
      return refresh(&state)

    case .refreshResponse(let result):
      let commandResults = commandResults(from: result)

      if let snapshot = result.snapshot, result.diagnostic == nil {
        state.sidebar.snapshot = snapshot
        state.sidebar.refreshState = .idle
        state.workspace.applySnapshot(
          snapshot,
          refreshState: .idle,
          commandResults: commandResults
        )
      } else {
        let refreshState = InventoryRefreshState.failed(
          diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
        )
        state.sidebar.refreshState = refreshState
        state.workspace.applyRefreshFailure(
          refreshState,
          commandResults: commandResults
        )
      }

      return .none

    case .createSimulatorButtonTapped:
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let formState = state.initialCreateDeviceFormState
      else {
        return .none
      }

      state.lifecycleSheet = .create(formState)
      return .none

    case .cloneSelectedSimulatorButtonTapped:
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let device = state.workspace.selectedDevice
      else {
        return .none
      }

      state.lifecycleSheet = .clone(
        CloneDeviceFormState(
          sourceDeviceID: device.id,
          sourceName: device.name,
          name: "\(device.name) Copy"
        )
      )
      return .none

    case .pairDevicesButtonTapped:
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let formState = state.initialPairDevicesFormState
      else {
        return .none
      }

      state.lifecycleSheet = .pair(formState)
      return .none

    case .lifecycleSheetDismissed:
      state.lifecycleSheet = nil
      return .none

    case .createDeviceSubmitted(let formState):
      state.lifecycleSheet = nil
      return runCreateDeviceCommand(&state, formState: formState)

    case .cloneDeviceSubmitted(let formState):
      state.lifecycleSheet = nil
      return runCloneDeviceCommand(&state, formState: formState)

    case .renameDeviceSubmitted(let formState):
      state.lifecycleSheet = nil
      return runRenameDeviceCommand(&state, formState: formState)

    case .eraseDeviceConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runEraseDeviceCommand(&state, confirmationState: confirmationState)

    case .deleteDeviceConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runDeleteDeviceCommand(&state, confirmationState: confirmationState)

    case .pairDevicesSubmitted(let formState):
      state.lifecycleSheet = nil
      return runPairDevicesCommand(&state, formState: formState)

    case .unpairDeviceConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runUnpairDeviceCommand(&state, confirmationState: confirmationState)

    case .uninstallAppConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runUninstallAppCommand(&state, confirmationState: confirmationState)

    case .resetAppSandboxConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runResetAppSandboxCommand(&state, confirmationState: confirmationState)

    case .installAppOnSimulatorSubmitted(let formState):
      state.lifecycleSheet = nil
      return runInstallAppOnSimulatorCommand(&state, formState: formState)

    case .openSimulatorAppButtonTapped:
      return openSimulatorApp(&state)

    case .openSimulatorAppResponse(let result):
      state.workspace.appendCommandResult(result)
      state.workspace.setOpeningSimulatorApp(false)
      return .none

    case .pathActionResults(let results):
      for result in results {
        state.workspace.appendCommandResult(result)
      }
      return .none

    case .developerToolCommandResults(let deviceCommandState, let results, let refreshAfterward):
      guard state.workspace.deviceCommandState == deviceCommandState else {
        return .none
      }

      for result in results {
        state.workspace.appendCommandResult(result)
      }

      if refreshAfterward {
        state.sidebar.refreshState = .refreshing
        state.workspace.setRefreshState(.refreshing)
      } else {
        state.workspace.setDeviceCommandState(nil)
      }

      return .none

    case .developerToolCommandRefreshResponse(
      let deviceCommandState,
      let result,
      let preferredSelectedDeviceID
    ):
      guard state.workspace.deviceCommandState == deviceCommandState else {
        return .none
      }

      let commandResults = state.workspace.commandResults + commandResults(from: result)

      if let snapshot = result.snapshot, result.diagnostic == nil {
        state.sidebar.snapshot = snapshot
        state.sidebar.refreshState = .idle
        state.workspace.applySnapshot(
          snapshot,
          refreshState: .idle,
          commandResults: commandResults,
          preferredSelectedDeviceID: preferredSelectedDeviceID
        )
      } else {
        let refreshState = InventoryRefreshState.failed(
          diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
        )
        state.sidebar.refreshState = refreshState
        state.workspace.applyRefreshFailure(
          refreshState,
          commandResults: commandResults
        )
      }

      state.workspace.setDeviceCommandState(nil)
      return .none

    case .deviceCommandResponse(let deviceCommandState, let result):
      guard state.workspace.deviceCommandState == deviceCommandState else {
        return .none
      }

      state.workspace.appendCommandResult(result)
      state.sidebar.refreshState = .refreshing
      state.workspace.setRefreshState(.refreshing)
      return .none

    case .deviceCommandRefreshResponse(let deviceCommandState, let result, let preferredSelectedDeviceID):
      guard state.workspace.deviceCommandState == deviceCommandState else {
        return .none
      }

      let commandResults = state.workspace.commandResults + commandResults(from: result)

      if let snapshot = result.snapshot, result.diagnostic == nil {
        state.sidebar.snapshot = snapshot
        state.sidebar.refreshState = .idle
        state.workspace.applySnapshot(
          snapshot,
          refreshState: .idle,
          commandResults: commandResults,
          preferredSelectedDeviceID: preferredSelectedDeviceID
        )
      } else {
        let refreshState = InventoryRefreshState.failed(
          diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
        )
        state.sidebar.refreshState = refreshState
        state.workspace.applyRefreshFailure(
          refreshState,
          commandResults: commandResults
        )
      }

      state.workspace.setDeviceCommandState(nil)
      return .none

    case .appCommandCommandsCompleted(
      let appCommandState,
      let commandResults,
      preferredSelectedDeviceID: _,
      preferredSelectedAppID: _
    ):
      guard state.workspace.appCommandState == appCommandState else {
        return .none
      }

      for commandResult in commandResults {
        state.workspace.appendCommandResult(commandResult)
      }
      state.sidebar.refreshState = .refreshing
      state.workspace.setRefreshState(.refreshing)
      return .none

    case .appCommandRefreshResponse(
      let appCommandState,
      let result,
      let preferredSelectedDeviceID,
      let preferredSelectedAppID
    ):
      guard state.workspace.appCommandState == appCommandState else {
        return .none
      }

      let commandResults = state.workspace.commandResults + commandResults(from: result)

      if let snapshot = result.snapshot, result.diagnostic == nil {
        state.sidebar.snapshot = snapshot
        state.sidebar.refreshState = .idle
        state.workspace.applySnapshot(
          snapshot,
          refreshState: .idle,
          commandResults: commandResults,
          preferredSelectedDeviceID: preferredSelectedDeviceID,
          preferredSelectedAppID: preferredSelectedAppID
        )
      } else {
        let refreshState = InventoryRefreshState.failed(
          diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
        )
        state.sidebar.refreshState = refreshState
        state.workspace.applyRefreshFailure(
          refreshState,
          commandResults: commandResults
        )
      }

      state.workspace.setAppCommandState(nil)
      return .none

    case .workspace(.deviceDetail(.bootButtonTapped(let deviceID))):
      return runDeviceCommand(
        &state,
        DeviceCommandState(command: .boot, deviceID: deviceID)
      )

    case .workspace(.deviceDetail(.shutdownButtonTapped(let deviceID))):
      return runDeviceCommand(
        &state,
        DeviceCommandState(command: .shutdown, deviceID: deviceID)
      )

    case .workspace(.deviceDetail(.openSimulatorAppButtonTapped)):
      return openSimulatorApp(&state)

    case .workspace(.deviceDetail(.renameButtonTapped(let deviceID))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let device = device(id: deviceID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .rename(
        RenameDeviceFormState(
          deviceID: device.id,
          currentName: device.name,
          name: device.name
        )
      )
      return .none

    case .workspace(.deviceDetail(.eraseButtonTapped(let deviceID))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = deviceDestructiveConfirmationState(
              deviceID: deviceID,
              in: state
            )
      else {
        return .none
      }

      state.lifecycleSheet = .erase(confirmationState)
      return .none

    case .workspace(.deviceDetail(.deleteButtonTapped(let deviceID))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = deviceDestructiveConfirmationState(
              deviceID: deviceID,
              in: state
            )
      else {
        return .none
      }

      state.lifecycleSheet = .delete(confirmationState)
      return .none

    case .workspace(.deviceDetail(.unpairButtonTapped(let pairID))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = unpairConfirmationState(pairID: pairID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .unpair(confirmationState)
      return .none

    case .workspace(.deviceDetail(.openDeviceDataFolderButtonTapped(let deviceID))),
         .workspace(.inspector(.openDeviceDataFolderButtonTapped(let deviceID))):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.dataPath },
        label: "device data folder",
        operation: .open
      )

    case .workspace(.deviceDetail(.copyDeviceDataPathButtonTapped(let deviceID))),
         .workspace(.inspector(.copyDeviceDataPathButtonTapped(let deviceID))):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.dataPath },
        label: "device data path",
        operation: .copy
      )

    case .workspace(.deviceDetail(.openDeviceLogFolderButtonTapped(let deviceID))),
         .workspace(.inspector(.openDeviceLogFolderButtonTapped(let deviceID))):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.logPath },
        label: "device log folder",
        operation: .open
      )

    case .workspace(.deviceDetail(.copyDeviceLogPathButtonTapped(let deviceID))),
         .workspace(.inspector(.copyDeviceLogPathButtonTapped(let deviceID))):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.logPath },
        label: "device log path",
        operation: .copy
      )

    case .workspace(.deviceDetail(.copyDeviceUDIDButtonTapped(let deviceID))),
         .workspace(.inspector(.copyDeviceUDIDButtonTapped(let deviceID))):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.udid },
        label: "device UDID"
      )

    case .workspace(.deviceDetail(.copyRuntimeIdentifierButtonTapped(let deviceID))),
         .workspace(.inspector(.copyRuntimeIdentifierButtonTapped(let deviceID))):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.runtimeID },
        label: "runtime identifier"
      )

    case .workspace(.deviceDetail(.copyDeviceTypeIdentifierButtonTapped(let deviceID))),
         .workspace(.inspector(.copyDeviceTypeIdentifierButtonTapped(let deviceID))):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.deviceTypeID },
        label: "device type identifier"
      )

    case .workspace(.deviceDetail(.installedApps(.launchButtonTapped(let appID)))):
      return runLaunchAppCommand(&state, appID: appID)

    case .workspace(.deviceDetail(.installedApps(.terminateButtonTapped(let appID)))):
      return runTerminateAppCommand(&state, appID: appID)

    case .workspace(.deviceDetail(.installedApps(.uninstallButtonTapped(let appID)))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = appDestructiveConfirmationState(
              appID: appID,
              in: state,
              includesDataContainer: false
            )
      else {
        return .none
      }

      state.lifecycleSheet = .uninstallApp(confirmationState)
      return .none

    case .workspace(.deviceDetail(.installedApps(.resetSandboxButtonTapped(let appID)))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = appDestructiveConfirmationState(
              appID: appID,
              in: state,
              includesDataContainer: true
            ),
            confirmationState.dataContainerPath != nil
      else {
        return .none
      }

      state.lifecycleSheet = .resetAppSandbox(confirmationState)
      return .none

    case .workspace(.deviceDetail(.installedApps(.installOnAnotherSimulatorButtonTapped(let appID)))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let formState = installAppTargetFormState(appID: appID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .installAppOnSimulator(formState)
      return .none

    case .workspace(.deviceDetail(.installedApps(.openBundleContainerButtonTapped(let appID)))),
         .workspace(.inspector(.openAppBundleContainerButtonTapped(let appID))):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .bundle,
        operation: .open
      )

    case .workspace(.deviceDetail(.installedApps(.copyBundleContainerButtonTapped(let appID)))),
         .workspace(.inspector(.copyAppBundleContainerButtonTapped(let appID))):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .bundle,
        operation: .copy
      )

    case .workspace(.deviceDetail(.installedApps(.openDataContainerButtonTapped(let appID)))),
         .workspace(.inspector(.openAppDataContainerButtonTapped(let appID))):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .data,
        operation: .open
      )

    case .workspace(.deviceDetail(.installedApps(.copyDataContainerButtonTapped(let appID)))),
         .workspace(.inspector(.copyAppDataContainerButtonTapped(let appID))):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .data,
        operation: .copy
      )

    case .workspace(.deviceDetail(.installedApps(.copyBundleIDButtonTapped(let appID)))),
         .workspace(.inspector(.copyAppBundleIDButtonTapped(let appID))):
      return runAppValueCopyAction(
        &state,
        appID: appID,
        value: { $0.bundleID },
        label: "app bundle identifier"
      )

    case .workspace(.deviceDetail(.installedApps(.openAppGroupContainerButtonTapped(let appID, let groupID)))),
         .workspace(.inspector(.openAppGroupContainerButtonTapped(let appID, let groupID))):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .appGroup(groupID),
        operation: .open
      )

    case .workspace(.deviceDetail(.installedApps(.copyAppGroupContainerButtonTapped(let appID, let groupID)))),
         .workspace(.inspector(.copyAppGroupContainerButtonTapped(let appID, let groupID))):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .appGroup(groupID),
        operation: .copy
      )

    case .workspace(.deviceDetail(.developerTools(.openDeepLinkButtonTapped))):
      return runOpenDeepLinkCommand(&state)

    case .workspace(.deviceDetail(.developerTools(.sendPushButtonTapped))):
      return runPushNotificationCommand(&state)

    case .workspace(.deviceDetail(.developerTools(.applyPrivacyButtonTapped))):
      return runPrivacyPermissionCommand(&state)

    case .workspace(.deviceDetail(.developerTools(.setLocationButtonTapped))):
      return runSetLocationCommand(&state)

    case .workspace(.deviceDetail(.developerTools(.clearLocationButtonTapped))):
      return runClearLocationCommand(&state)

    case .workspace(.deviceDetail(.developerTools(.setStatusBarOverrideButtonTapped))):
      return runSetStatusBarOverrideCommand(&state)

    case .workspace(.deviceDetail(.developerTools(.clearStatusBarOverrideButtonTapped))):
      return runClearStatusBarOverrideCommand(&state)

    case .sidebar, .workspace:
      return .none
    }
  }
}
