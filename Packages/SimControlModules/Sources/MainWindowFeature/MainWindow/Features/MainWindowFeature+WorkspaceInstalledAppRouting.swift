import ComposableArchitecture
import WorkspaceFeature

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
