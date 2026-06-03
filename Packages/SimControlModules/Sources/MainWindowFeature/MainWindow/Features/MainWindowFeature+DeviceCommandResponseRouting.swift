import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature Device Command Response Routing
extension MainWindowFeature {
  func routeDeviceCommandResponse(
    _ deviceCommandState: DeviceCommandState,
    _ result: CommandResult,
    into state: inout State
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == deviceCommandState else {
      return .none
    }

    state.workspace.appendCommandResult(result)
    state.sidebar.refreshState = .refreshing
    state.workspace.setRefreshState(.refreshing)
    return .none
  }

  func routeDeviceCommandRefreshResponse(
    _ deviceCommandState: DeviceCommandState,
    _ result: SimulatorRefreshResult,
    preferredSelectedDeviceID: String?,
    into state: inout State
  ) -> Effect<Action> {
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
  }
}
