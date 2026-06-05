import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature Command Response Routing
extension MainWindowFeature {
  func routeCommandResponseAction(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case .pathActionResults(let results):
      return routePathActionResults(results, into: &state)

    case .developerToolCommandResults(let deviceCommandState, let results, let refreshAfterward):
      return routeDeveloperToolCommandResults(
        deviceCommandState,
        results,
        refreshAfterward: refreshAfterward,
        into: &state
      )

    case .developerToolCommandRefreshResponse(
      let deviceCommandState,
      let result,
      let preferredSelectedDeviceID
    ):
      return routeDeveloperToolCommandRefreshResponse(
        deviceCommandState,
        result,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        into: &state
      )

    case .deviceCommandResponse(let deviceCommandState, let result):
      return routeDeviceCommandResponse(deviceCommandState, result, into: &state)

    case .deviceCommandRefreshResponse(let deviceCommandState, let result, let preferredSelectedDeviceID):
      return routeDeviceCommandRefreshResponse(
        deviceCommandState,
        result,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        into: &state
      )

    case .appCommandCommandsCompleted(
      let appCommandState,
      let commandResults,
      preferredSelectedDeviceID: _,
      preferredSelectedAppID: _
    ):
      return routeAppCommandCommandsCompleted(
        appCommandState,
        commandResults,
        into: &state
      )

    case .appCommandRefreshResponse(
      let appCommandState,
      let result,
      let preferredSelectedDeviceID,
      let preferredSelectedAppID
    ):
      return routeAppCommandRefreshResponse(
        appCommandState,
        result,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        preferredSelectedAppID: preferredSelectedAppID,
        into: &state
      )

    default:
      return .none
    }
  }
}

// MARK: - MainWindowFeature Path Command Response Routing

extension MainWindowFeature {
  func routePathActionResults(
    _: [CommandResult],
    into state: inout State
  ) -> Effect<Action> {
    return .none
  }
}

// MARK: - MainWindowFeature Developer Tool Command Response Routing

extension MainWindowFeature {
  func routeDeveloperToolCommandResults(
    _ deviceCommandState: DeviceCommandState,
    _: [CommandResult],
    refreshAfterward: Bool,
    into state: inout State
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == deviceCommandState else {
      return .none
    }

    if refreshAfterward {
      state.sidebar.refreshState = .refreshing
      state.workspace.setRefreshState(.refreshing)
    } else {
      state.workspace.setDeviceCommandState(nil)
    }

    return .none
  }

  func routeDeveloperToolCommandRefreshResponse(
    _ deviceCommandState: DeviceCommandState,
    _ result: SimulatorRefreshResult,
    preferredSelectedDeviceID: String?,
    into state: inout State
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == deviceCommandState else {
      return .none
    }

    if let snapshot = result.snapshot, result.diagnostic == nil {
      state.sidebar.snapshot = snapshot
      state.sidebar.refreshState = .idle
      state.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        preferredSelectedDeviceID: preferredSelectedDeviceID
      )
    } else {
      let refreshState = InventoryRefreshState.failed(
        diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
      )
      state.sidebar.refreshState = refreshState
      state.workspace.applyRefreshFailure(refreshState)
    }

    state.workspace.setDeviceCommandState(nil)
    return .none
  }
}

// MARK: - MainWindowFeature Device Command Response Routing

extension MainWindowFeature {
  func routeDeviceCommandResponse(
    _ deviceCommandState: DeviceCommandState,
    _: CommandResult,
    into state: inout State
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == deviceCommandState else {
      return .none
    }

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

    if let snapshot = result.snapshot, result.diagnostic == nil {
      state.sidebar.snapshot = snapshot
      state.sidebar.refreshState = .idle
      state.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        preferredSelectedDeviceID: preferredSelectedDeviceID
      )
    } else {
      let refreshState = InventoryRefreshState.failed(
        diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
      )
      state.sidebar.refreshState = refreshState
      state.workspace.applyRefreshFailure(refreshState)
    }

    state.workspace.setDeviceCommandState(nil)
    return .none
  }
}

// MARK: - MainWindowFeature App Command Response Routing

extension MainWindowFeature {
  func routeAppCommandCommandsCompleted(
    _ appCommandState: AppCommandState,
    _: [CommandResult],
    into state: inout State
  ) -> Effect<Action> {
    guard state.workspace.appCommandState == appCommandState else {
      return .none
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

    if let snapshot = result.snapshot, result.diagnostic == nil {
      state.sidebar.snapshot = snapshot
      state.sidebar.refreshState = .idle
      state.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        preferredSelectedAppID: preferredSelectedAppID
      )
    } else {
      let refreshState = InventoryRefreshState.failed(
        diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
      )
      state.sidebar.refreshState = refreshState
      state.workspace.applyRefreshFailure(refreshState)
    }

    state.workspace.setAppCommandState(nil)
    return .none
  }
}
