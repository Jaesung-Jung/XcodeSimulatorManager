import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature Inventory

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

  func autoRefreshFromMenuBar(
    _ state: inout State,
    at date: Date
  ) -> Effect<Action> {
    guard state.workspace.refreshState != .refreshing,
          snapshotNeedsMenuBarRefresh(state.workspace.snapshot, at: date),
          canAttemptMenuBarAutoRefresh(state, at: date)
    else {
      return .none
    }

    state.lastMenuBarAutoRefreshAttemptAt = date
    return refresh(&state)
  }

  func refresh(_ state: inout State) -> Effect<Action> {
    guard state.workspace.refreshState != .refreshing else {
      return .none
    }

    state.sidebar.refreshState = .refreshing
    state.workspace.setRefreshState(.refreshing)

    return .run { [inventoryWorkflow] send in
      await send(.refreshResponse(await inventoryWorkflow.refresh()))
    }
  }

  func openSimulatorApp(_ state: inout State) -> Effect<Action> {
    guard !state.workspace.isOpeningSimulatorApp else {
      return .none
    }

    state.workspace.setOpeningSimulatorApp(true)

    return .run { [inventoryWorkflow] send in
      let commandResult = await inventoryWorkflow.openSimulatorApp()
      await send(.openSimulatorAppResponse(commandResult))
    }
  }

  func snapshotNeedsMenuBarRefresh(
    _ snapshot: SimulatorSnapshot?,
    at date: Date
  ) -> Bool {
    guard let snapshot else {
      return true
    }

    return date.timeIntervalSince(snapshot.generatedAt) >= Self.menuBarAutoRefreshInterval
  }

  func canAttemptMenuBarAutoRefresh(
    _ state: State,
    at date: Date
  ) -> Bool {
    guard let lastMenuBarAutoRefreshAttemptAt = state.lastMenuBarAutoRefreshAttemptAt else {
      return true
    }

    return date.timeIntervalSince(lastMenuBarAutoRefreshAttemptAt) >= Self.menuBarAutoRefreshInterval
  }

  func commandResults(
    from result: SimulatorRefreshResult
  ) -> [CommandResult] {
    var results = [result.xcodeCommandResult]

    if let listCommandResult = result.listCommandResult {
      results.append(listCommandResult)
    }

    return results
  }
}
