import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature App Command Response Routing
extension MainWindowFeature {
  func routeAppCommandCommandsCompleted(
    _ appCommandState: AppCommandState,
    _ commandResults: [CommandResult],
    into state: inout State
  ) -> Effect<Action> {
    guard state.workspace.appCommandState == appCommandState else {
      return .none
    }

    for commandResult in commandResults {
      state.workspace.appendCommandResult(commandResult)
    }
    state.sidebar.refreshState = .refreshing
    state.workspace.setRefreshState(.refreshing)
    return .none
  }

  func routeAppCommandRefreshResponse(
    _ appCommandState: AppCommandState,
    _ result: SimulatorRefreshResult,
    preferredSelectedDeviceID: String?,
    preferredSelectedAppID: String?,
    into state: inout State
  ) -> Effect<Action> {
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
  }
}
