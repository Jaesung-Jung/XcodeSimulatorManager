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
      deviceCommandState: DeviceCommandState? = nil,
      isOpeningSimulatorApp: Bool = false,
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
        installedAppsAvailability: installedAppsAvailability,
        deviceCommandState: deviceCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp
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
    case deviceCommandResponse(DeviceCommandState, CommandResult)
    case deviceCommandRefreshResponse(DeviceCommandState, SimulatorRepository.RefreshResult)
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
        return openSimulatorApp(&state)

      case .openSimulatorAppResponse(let result):
        state.workspace.appendCommandResult(result)
        state.workspace.setOpeningSimulatorApp(false)
        return .none

      case .deviceCommandResponse(let deviceCommandState, let result):
        guard state.workspace.deviceCommandState == deviceCommandState else {
          return .none
        }

        state.workspace.appendCommandResult(result)
        state.sidebar.refreshState = .refreshing
        state.workspace.setRefreshState(.refreshing)
        return .none

      case .deviceCommandRefreshResponse(let deviceCommandState, let result):
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

        state.workspace.setDeviceCommandState(nil)
        return .none

      case .workspace(.deviceDetail(.bootButtonTapped(let deviceID))):
        return runDeviceCommand(
          &state,
          DeviceCommandState(command: .boot, deviceID: deviceID)
        )

      case .workspace(.deviceDetail(.shutdownButtonTapped(let deviceID))):
        return runDeviceCommand(
          &state,
          DeviceCommandState(command: .shutdown, deviceID: deviceID)
        )

      case .workspace(.deviceDetail(.openSimulatorAppButtonTapped)):
        return openSimulatorApp(&state)

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

  private func openSimulatorApp(_ state: inout State) -> Effect<Action> {
    guard !state.workspace.isOpeningSimulatorApp else {
      return .none
    }

    state.workspace.setOpeningSimulatorApp(true)

    return .run { [coreSimulatorService] send in
      let commandResult = await coreSimulatorService.openSimulatorApp()
      await send(.openSimulatorAppResponse(commandResult))
    }
  }

  private func runDeviceCommand(
    _ state: inout State,
    _ deviceCommandState: DeviceCommandState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          let device = device(id: deviceCommandState.deviceID, in: state),
          canRun(deviceCommandState.command, on: device)
    else {
      return .none
    }

    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult: CommandResult

      switch deviceCommandState.command {
      case .boot:
        commandResult = await coreSimulatorService.bootDevice(deviceCommandState.deviceID)
      case .shutdown:
        commandResult = await coreSimulatorService.shutdownDevice(deviceCommandState.deviceID)
      }

      await send(.deviceCommandResponse(deviceCommandState, commandResult))
      let refreshResult = await simulatorRepository.refresh()
      await send(.deviceCommandRefreshResponse(deviceCommandState, refreshResult))
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

  private func device(id: String, in state: State) -> SimulatorDevice? {
    state.workspace.snapshot?.devices.first { $0.id == id }
  }

  private func canRun(
    _ command: DeviceCommand,
    on device: SimulatorDevice
  ) -> Bool {
    guard device.isAvailable else {
      return false
    }

    switch command {
    case .boot:
      return device.state == .shutdown
    case .shutdown:
      return device.state == .booted
    }
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
