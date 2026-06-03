import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature Inventory

extension MainWindowFeature {
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

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = InventoryWorkflowClient.live(
        simulatorRepository: simulatorRepository,
        coreSimulatorService: coreSimulatorService
      )
      await send(.refreshResponse(await workflow.refresh()))
    }
  }

  func openSimulatorApp(_ state: inout State) -> Effect<Action> {
    guard !state.workspace.isOpeningSimulatorApp else {
      return .none
    }

    state.workspace.setOpeningSimulatorApp(true)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = InventoryWorkflowClient.live(
        simulatorRepository: simulatorRepository,
        coreSimulatorService: coreSimulatorService
      )
      let commandResult = await workflow.openSimulatorApp()
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
