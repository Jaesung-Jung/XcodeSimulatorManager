import ComposableArchitecture
import MainWindowFeatureSupport
import WorkspaceFeature

// MARK: - MainWindowFeature Workspace Routing
extension MainWindowFeature {
  func routeWorkspaceAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.bootButtonTapped),
         .deviceDetail(.shutdownButtonTapped),
         .deviceDetail(.openSimulatorAppButtonTapped),
         .deviceDetail(.renameButtonTapped),
         .deviceDetail(.eraseButtonTapped),
         .deviceDetail(.deleteButtonTapped),
         .deviceDetail(.unpairButtonTapped):
      return routeWorkspaceDeviceAction(action, into: &state)

    case .deviceDetail(.openDeviceDataFolderButtonTapped),
         .deviceDetail(.copyDeviceDataPathButtonTapped),
         .deviceDetail(.openDeviceLogFolderButtonTapped),
         .deviceDetail(.copyDeviceLogPathButtonTapped),
         .deviceDetail(.copyDeviceUDIDButtonTapped),
         .deviceDetail(.copyRuntimeIdentifierButtonTapped),
         .deviceDetail(.copyDeviceTypeIdentifierButtonTapped),
         .inspector(.openDeviceDataFolderButtonTapped),
         .inspector(.copyDeviceDataPathButtonTapped),
         .inspector(.openDeviceLogFolderButtonTapped),
         .inspector(.copyDeviceLogPathButtonTapped),
         .inspector(.copyDeviceUDIDButtonTapped),
         .inspector(.copyRuntimeIdentifierButtonTapped),
         .inspector(.copyDeviceTypeIdentifierButtonTapped):
      return routeWorkspacePathAction(action, into: &state)

    case .deviceDetail(.installedApps),
         .inspector(.openAppBundleContainerButtonTapped),
         .inspector(.copyAppBundleContainerButtonTapped),
         .inspector(.openAppDataContainerButtonTapped),
         .inspector(.copyAppDataContainerButtonTapped),
         .inspector(.copyAppBundleIDButtonTapped),
         .inspector(.openAppGroupContainerButtonTapped),
         .inspector(.copyAppGroupContainerButtonTapped):
      return routeWorkspaceInstalledAppAction(action, into: &state)

    case .deviceDetail(.developerTools):
      return routeWorkspaceDeveloperToolAction(action, into: &state)

    default:
      return .none
    }
  }
}

// MARK: - MainWindowFeature Workspace Device Routing

extension MainWindowFeature {
  func routeWorkspaceDeviceAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.bootButtonTapped(let deviceID)):
      return runDeviceCommand(
        &state,
        DeviceCommandState(command: .boot, deviceID: deviceID)
      )

    case .deviceDetail(.shutdownButtonTapped(let deviceID)):
      return runDeviceCommand(
        &state,
        DeviceCommandState(command: .shutdown, deviceID: deviceID)
      )

    case .deviceDetail(.openSimulatorAppButtonTapped):
      return openSimulatorApp(&state)

    case .deviceDetail(.renameButtonTapped(let deviceID)):
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

    case .deviceDetail(.eraseButtonTapped(let deviceID)):
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

    case .deviceDetail(.deleteButtonTapped(let deviceID)):
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

    case .deviceDetail(.unpairButtonTapped(let pairID)):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = unpairConfirmationState(pairID: pairID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .unpair(confirmationState)
      return .none

    default:
      return .none
    }
  }
}

// MARK: - MainWindowFeature Workspace Path Routing

extension MainWindowFeature {
  func routeWorkspacePathAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.openDeviceDataFolderButtonTapped(let deviceID)),
         .inspector(.openDeviceDataFolderButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.dataPath },
        label: "device data folder",
        operation: .open
      )

    case .deviceDetail(.copyDeviceDataPathButtonTapped(let deviceID)),
         .inspector(.copyDeviceDataPathButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.dataPath },
        label: "device data path",
        operation: .copy
      )

    case .deviceDetail(.openDeviceLogFolderButtonTapped(let deviceID)),
         .inspector(.openDeviceLogFolderButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.logPath },
        label: "device log folder",
        operation: .open
      )

    case .deviceDetail(.copyDeviceLogPathButtonTapped(let deviceID)),
         .inspector(.copyDeviceLogPathButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.logPath },
        label: "device log path",
        operation: .copy
      )

    case .deviceDetail(.copyDeviceUDIDButtonTapped(let deviceID)),
         .inspector(.copyDeviceUDIDButtonTapped(let deviceID)):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.udid },
        label: "device UDID"
      )

    case .deviceDetail(.copyRuntimeIdentifierButtonTapped(let deviceID)),
         .inspector(.copyRuntimeIdentifierButtonTapped(let deviceID)):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.runtimeID },
        label: "runtime identifier"
      )

    case .deviceDetail(.copyDeviceTypeIdentifierButtonTapped(let deviceID)),
         .inspector(.copyDeviceTypeIdentifierButtonTapped(let deviceID)):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.deviceTypeID },
        label: "device type identifier"
      )

    default:
      return .none
    }
  }
}

// MARK: - MainWindowFeature Workspace Installed App Routing

extension MainWindowFeature {
  func routeWorkspaceInstalledAppAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.installedApps(.launchButtonTapped(let appID))):
      return runLaunchAppCommand(&state, appID: appID)

    case .deviceDetail(.installedApps(.terminateButtonTapped(let appID))):
      return runTerminateAppCommand(&state, appID: appID)

    case .deviceDetail(.installedApps(.uninstallButtonTapped(let appID))):
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

    case .deviceDetail(.installedApps(.resetSandboxButtonTapped(let appID))):
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

    case .deviceDetail(.installedApps(.installOnAnotherSimulatorButtonTapped(let appID))):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let formState = installAppTargetFormState(appID: appID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .installAppOnSimulator(formState)
      return .none

    case .deviceDetail(.installedApps(.openBundleContainerButtonTapped(let appID))),
         .inspector(.openAppBundleContainerButtonTapped(let appID)):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .bundle,
        operation: .open
      )

    case .deviceDetail(.installedApps(.copyBundleContainerButtonTapped(let appID))),
         .inspector(.copyAppBundleContainerButtonTapped(let appID)):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .bundle,
        operation: .copy
      )

    case .deviceDetail(.installedApps(.openDataContainerButtonTapped(let appID))),
         .inspector(.openAppDataContainerButtonTapped(let appID)):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .data,
        operation: .open
      )

    case .deviceDetail(.installedApps(.copyDataContainerButtonTapped(let appID))),
         .inspector(.copyAppDataContainerButtonTapped(let appID)):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .data,
        operation: .copy
      )

    case .deviceDetail(.installedApps(.copyBundleIDButtonTapped(let appID))),
         .inspector(.copyAppBundleIDButtonTapped(let appID)):
      return runAppValueCopyAction(
        &state,
        appID: appID,
        value: { $0.bundleID },
        label: "app bundle identifier"
      )

    case .deviceDetail(.installedApps(.openAppGroupContainerButtonTapped(let appID, let groupID))),
         .inspector(.openAppGroupContainerButtonTapped(let appID, let groupID)):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .appGroup(groupID),
        operation: .open
      )

    case .deviceDetail(.installedApps(.copyAppGroupContainerButtonTapped(let appID, let groupID))),
         .inspector(.copyAppGroupContainerButtonTapped(let appID, let groupID)):
      return runAppContainerPathAction(
        &state,
        appID: appID,
        target: .appGroup(groupID),
        operation: .copy
      )

    default:
      return .none
    }
  }
}

// MARK: - MainWindowFeature Workspace Developer Tool Routing

extension MainWindowFeature {
  func routeWorkspaceDeveloperToolAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.developerTools(.openDeepLinkButtonTapped)):
      return runOpenDeepLinkCommand(&state)

    case .deviceDetail(.developerTools(.sendPushButtonTapped)):
      return runPushNotificationCommand(&state)

    case .deviceDetail(.developerTools(.applyPrivacyButtonTapped)):
      return runPrivacyPermissionCommand(&state)

    case .deviceDetail(.developerTools(.setLocationButtonTapped)):
      return runSetLocationCommand(&state)

    case .deviceDetail(.developerTools(.clearLocationButtonTapped)):
      return runClearLocationCommand(&state)

    case .deviceDetail(.developerTools(.setStatusBarOverrideButtonTapped)):
      return runSetStatusBarOverrideCommand(&state)

    case .deviceDetail(.developerTools(.clearStatusBarOverrideButtonTapped)):
      return runClearStatusBarOverrideCommand(&state)

    default:
      return .none
    }
  }
}
