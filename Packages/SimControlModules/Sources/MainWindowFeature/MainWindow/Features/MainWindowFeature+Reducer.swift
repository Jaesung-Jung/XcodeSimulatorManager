import ComposableArchitecture

// MARK: - MainWindowFeature Reducer
extension MainWindowFeature {
  func route(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case .task,
         .menuBar,
         .refreshButtonTapped,
         .refreshResponse,
         .openSimulatorAppButtonTapped,
         .openSimulatorAppResponse:
      return routeMenuRefreshAction(into: &state, action: action)

    case .createSimulatorButtonTapped,
         .cloneSelectedSimulatorButtonTapped,
         .pairDevicesButtonTapped,
         .lifecycleSheetDismissed,
         .createDeviceSubmitted,
         .cloneDeviceSubmitted,
         .renameDeviceSubmitted,
         .eraseDeviceConfirmed,
         .deleteDeviceConfirmed,
         .pairDevicesSubmitted,
         .unpairDeviceConfirmed,
         .uninstallAppConfirmed,
         .resetAppSandboxConfirmed,
         .installAppOnSimulatorSubmitted:
      return routeSheetAction(into: &state, action: action)

    case .pathActionResults,
         .developerToolCommandResults,
         .developerToolCommandRefreshResponse,
         .deviceCommandResponse,
         .deviceCommandRefreshResponse,
         .appCommandCommandsCompleted,
         .appCommandRefreshResponse:
      return routeCommandResponseAction(into: &state, action: action)

    case .workspace(let workspaceAction):
      return routeWorkspaceAction(workspaceAction, into: &state)

    case .sidebar:
      return .none
    }
  }
}
