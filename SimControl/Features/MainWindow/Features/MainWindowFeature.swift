import ComposableArchitecture
import Foundation

@Reducer
struct MainWindowFeature {
  private static let menuBarAutoRefreshInterval: TimeInterval = 60

  @Dependency(\.coreSimulatorService) private var coreSimulatorService
  @Dependency(\.simulatorRepository) private var simulatorRepository

  @ObservableState
  struct State: Equatable {
    var lastMenuBarAutoRefreshAttemptAt: Date?
    var sidebar: SidebarFeature.State
    var workspace: WorkspaceFeature.State

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      selectedDeviceID: String? = nil,
      selectedAppID: String? = nil,
      lastCommandResults: [CommandResult] = [],
      installedAppsAvailability: InstalledAppsAvailability = .notLoaded,
      lastMenuBarAutoRefreshAttemptAt: Date? = nil
    ) {
      self.lastMenuBarAutoRefreshAttemptAt = lastMenuBarAutoRefreshAttemptAt
      self.sidebar = SidebarFeature.State(
        snapshot: snapshot,
        refreshState: refreshState
      )
      self.workspace = WorkspaceFeature.State(
        snapshot: snapshot,
        refreshState: refreshState,
        selectedDeviceID: selectedDeviceID,
        selectedAppID: selectedAppID,
        commandResults: lastCommandResults,
        installedAppsAvailability: installedAppsAvailability
      )
    }
  }

  enum Action: Equatable {
    case task
    case menuBarPresented(at: Date)
    case refreshButtonTapped
    case refreshResponse(SimulatorRepository.RefreshResult)
    case openSimulatorAppButtonTapped
    case openSimulatorAppResponse(CommandResult)
    case sidebar(SidebarFeature.Action)
    case workspace(WorkspaceFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard state.workspace.snapshot == nil else {
          return .none
        }

        return refresh(&state)

      case .menuBarPresented(let date):
        return autoRefreshFromMenuBar(&state, at: date)

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
        return .run { [coreSimulatorService] send in
          await send(.openSimulatorAppResponse(await coreSimulatorService.openSimulatorApp()))
        }

      case .openSimulatorAppResponse(let result):
        state.workspace.appendCommandResult(result)
        return .none

      case .sidebar, .workspace:
        return .none
      }
    }

    Scope(state: \.sidebar, action: \.sidebar) {
      SidebarFeature()
    }
    Scope(state: \.workspace, action: \.workspace) {
      WorkspaceFeature()
    }
  }

  private func autoRefreshFromMenuBar(
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

  private func refresh(_ state: inout State) -> Effect<Action> {
    guard state.workspace.refreshState != .refreshing else {
      return .none
    }

    state.sidebar.refreshState = .refreshing
    state.workspace.setRefreshState(.refreshing)

    return .run { [simulatorRepository] send in
      await send(.refreshResponse(await simulatorRepository.refresh()))
    }
  }

  private func snapshotNeedsMenuBarRefresh(
    _ snapshot: SimulatorSnapshot?,
    at date: Date
  ) -> Bool {
    guard let snapshot else {
      return true
    }

    return date.timeIntervalSince(snapshot.generatedAt) >= Self.menuBarAutoRefreshInterval
  }

  private func canAttemptMenuBarAutoRefresh(
    _ state: State,
    at date: Date
  ) -> Bool {
    guard let lastMenuBarAutoRefreshAttemptAt = state.lastMenuBarAutoRefreshAttemptAt else {
      return true
    }

    return date.timeIntervalSince(lastMenuBarAutoRefreshAttemptAt) >= Self.menuBarAutoRefreshInterval
  }

  private func commandResults(
    from result: SimulatorRepository.RefreshResult
  ) -> [CommandResult] {
    var results = [result.xcodeCommandResult]

    if let listCommandResult = result.listCommandResult {
      results.append(listCommandResult)
    }

    return results
  }
}
