import ComposableArchitecture
import MainWindowFeatureSupport

// MARK: - MainWindowFeature Command Response Routing
extension MainWindowFeature {
  func routeCommandResponseAction(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
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

    default:
      return .none
    }
  }
}
