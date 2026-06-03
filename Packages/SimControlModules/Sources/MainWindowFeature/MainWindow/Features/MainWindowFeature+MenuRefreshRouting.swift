import ComposableArchitecture
import MainWindowFeatureSupport

// MARK: - MainWindowFeature Menu and Refresh Routing
extension MainWindowFeature {
  func routeMenuRefreshAction(
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

    case .openSimulatorAppButtonTapped:
      return openSimulatorApp(&state)

    case .openSimulatorAppResponse(let result):
      state.workspace.appendCommandResult(result)
      state.workspace.setOpeningSimulatorApp(false)
      return .none

    default:
      return .none
    }
  }
}
