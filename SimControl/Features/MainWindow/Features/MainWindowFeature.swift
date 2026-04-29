import ComposableArchitecture
import Foundation

@Reducer
struct MainWindowFeature {
  private static let menuBarAutoRefreshInterval: TimeInterval = 60

  @Dependency(\.coreSimulatorService) private var coreSimulatorService
  @Dependency(\.simulatorRepository) private var simulatorRepository

  enum DeviceLifecycleSheet: Equatable, Identifiable {
    case create(CreateDeviceFormState)
    case clone(CloneDeviceFormState)
    case rename(RenameDeviceFormState)
    case erase(DeviceDestructiveConfirmationState)
    case delete(DeviceDestructiveConfirmationState)
    case pair(PairDevicesFormState)
    case unpair(UnpairDeviceConfirmationState)

    var id: String {
      switch self {
      case .create:
        "create"
      case .clone(let formState):
        "clone-\(formState.sourceDeviceID)"
      case .rename(let formState):
        "rename-\(formState.deviceID)"
      case .erase(let confirmationState):
        "erase-\(confirmationState.deviceID)"
      case .delete(let confirmationState):
        "delete-\(confirmationState.deviceID)"
      case .pair:
        "pair"
      case .unpair(let confirmationState):
        "unpair-\(confirmationState.pairID)"
      }
    }
  }

  struct DeviceDestructiveConfirmationState: Equatable {
    let deviceID: String
    let deviceName: String
    let deviceUDID: String
  }

  struct CreateDeviceFormState: Equatable {
    var name: String
    var runtimeID: String
    var deviceTypeID: String

    init(
      name: String = "",
      runtimeID: String = "",
      deviceTypeID: String = ""
    ) {
      self.name = name
      self.runtimeID = runtimeID
      self.deviceTypeID = deviceTypeID
    }
  }

  struct CloneDeviceFormState: Equatable {
    let sourceDeviceID: String
    let sourceName: String
    var name: String
  }

  struct RenameDeviceFormState: Equatable {
    let deviceID: String
    let currentName: String
    var name: String
  }

  struct PairDeviceCandidate: Equatable, Identifiable {
    let id: String
    let name: String
    let udid: String

    init(device: SimulatorDevice) {
      self.id = device.id
      self.name = device.name
      self.udid = device.udid
    }
  }

  struct PairDevicesFormState: Equatable {
    var phoneDeviceID: String
    var watchDeviceID: String
  }

  struct UnpairDeviceConfirmationState: Equatable {
    let pairID: String
    let phoneName: String
    let phoneUDID: String
    let watchName: String
    let watchUDID: String
  }

  @ObservableState
  struct State: Equatable {
    var lastMenuBarAutoRefreshAttemptAt: Date?
    var lifecycleSheet: DeviceLifecycleSheet?
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
      lastMenuBarAutoRefreshAttemptAt: Date? = nil,
      lifecycleSheet: DeviceLifecycleSheet? = nil
    ) {
      self.lastMenuBarAutoRefreshAttemptAt = lastMenuBarAutoRefreshAttemptAt
      self.lifecycleSheet = lifecycleSheet
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

    var canCreateDevice: Bool {
      workspace.deviceCommandState == nil && initialCreateDeviceFormState != nil
    }

    var canCloneSelectedDevice: Bool {
      workspace.deviceCommandState == nil && workspace.selectedDevice != nil
    }

    var canPairDevices: Bool {
      workspace.deviceCommandState == nil && initialPairDevicesFormState != nil
    }

    var initialCreateDeviceFormState: CreateDeviceFormState? {
      guard let snapshot else {
        return nil
      }

      return Self.initialCreateDeviceFormState(in: snapshot)
    }

    var initialPairDevicesFormState: PairDevicesFormState? {
      guard let snapshot else {
        return nil
      }

      return Self.initialPairDevicesFormState(
        in: snapshot,
        selectedDeviceID: workspace.deviceList.selectedDeviceID
      )
    }

    var pairPhoneCandidates: [PairDeviceCandidate] {
      guard let snapshot else {
        return []
      }

      return Self.pairPhoneCandidates(in: snapshot)
    }

    var pairWatchCandidates: [PairDeviceCandidate] {
      guard let snapshot else {
        return []
      }

      return Self.pairWatchCandidates(in: snapshot)
    }

    private var snapshot: SimulatorSnapshot? {
      workspace.snapshot
    }

    private static func initialCreateDeviceFormState(
      in snapshot: SimulatorSnapshot
    ) -> CreateDeviceFormState? {
      for runtime in snapshot.runtimes where runtime.isAvailable {
        guard let deviceType = compatibleDeviceTypes(
          for: runtime,
          in: snapshot.deviceTypes
        ).first else {
          continue
        }

        return CreateDeviceFormState(
          runtimeID: runtime.id,
          deviceTypeID: deviceType.id
        )
      }

      return nil
    }

    private static func compatibleDeviceTypes(
      for runtime: SimulatorRuntime,
      in deviceTypes: [SimulatorDeviceType]
    ) -> [SimulatorDeviceType] {
      guard !runtime.supportedDeviceTypeIDs.isEmpty else {
        return deviceTypes
      }

      let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
      return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
    }

    private static func initialPairDevicesFormState(
      in snapshot: SimulatorSnapshot,
      selectedDeviceID: String?
    ) -> PairDevicesFormState? {
      let phoneCandidates = pairPhoneCandidates(in: snapshot)
      let watchCandidates = pairWatchCandidates(in: snapshot)

      guard !phoneCandidates.isEmpty, !watchCandidates.isEmpty else {
        return nil
      }

      let selectedPhoneID = phoneCandidates.first { $0.id == selectedDeviceID }?.id
      let selectedWatchID = watchCandidates.first { $0.id == selectedDeviceID }?.id

      return PairDevicesFormState(
        phoneDeviceID: selectedPhoneID ?? phoneCandidates[0].id,
        watchDeviceID: selectedWatchID ?? watchCandidates[0].id
      )
    }

    private static func pairPhoneCandidates(
      in snapshot: SimulatorSnapshot
    ) -> [PairDeviceCandidate] {
      snapshot.devices
        .filter { isPairPhoneCandidate($0, in: snapshot) }
        .map { PairDeviceCandidate(device: $0) }
    }

    private static func pairWatchCandidates(
      in snapshot: SimulatorSnapshot
    ) -> [PairDeviceCandidate] {
      let pairedWatchDeviceIDs = Set(snapshot.pairs.map(\.watchDeviceID))

      return snapshot.devices
        .filter {
          isPairWatchCandidate(
            $0,
            in: snapshot,
            pairedWatchDeviceIDs: pairedWatchDeviceIDs
          )
        }
        .map { PairDeviceCandidate(device: $0) }
    }

    private static func isPairPhoneCandidate(
      _ device: SimulatorDevice,
      in snapshot: SimulatorSnapshot
    ) -> Bool {
      guard device.isAvailable,
            device.platform == .iOS,
            let deviceType = snapshot.deviceTypes.first(where: { $0.id == device.deviceTypeID })
      else {
        return false
      }

      return deviceType.productFamily == "iPhone"
    }

    private static func isPairWatchCandidate(
      _ device: SimulatorDevice,
      in snapshot: SimulatorSnapshot,
      pairedWatchDeviceIDs: Set<String>
    ) -> Bool {
      guard device.isAvailable,
            device.platform == .watchOS,
            !pairedWatchDeviceIDs.contains(device.id),
            let deviceType = snapshot.deviceTypes.first(where: { $0.id == device.deviceTypeID })
      else {
        return false
      }

      return deviceType.productFamily == "Apple Watch"
    }
  }

  enum Action: Equatable {
    case task
    case menuBarPresented(at: Date)
    case refreshButtonTapped
    case refreshResponse(SimulatorRepository.RefreshResult)
    case createSimulatorButtonTapped
    case cloneSelectedSimulatorButtonTapped
    case pairDevicesButtonTapped
    case lifecycleSheetDismissed
    case createDeviceSubmitted(CreateDeviceFormState)
    case cloneDeviceSubmitted(CloneDeviceFormState)
    case renameDeviceSubmitted(RenameDeviceFormState)
    case eraseDeviceConfirmed(DeviceDestructiveConfirmationState)
    case deleteDeviceConfirmed(DeviceDestructiveConfirmationState)
    case pairDevicesSubmitted(PairDevicesFormState)
    case unpairDeviceConfirmed(UnpairDeviceConfirmationState)
    case openSimulatorAppButtonTapped
    case openSimulatorAppResponse(CommandResult)
    case deviceCommandResponse(DeviceCommandState, CommandResult)
    case deviceCommandRefreshResponse(
      DeviceCommandState,
      SimulatorRepository.RefreshResult,
      preferredSelectedDeviceID: String?
    )
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

      case .createSimulatorButtonTapped:
        guard state.workspace.deviceCommandState == nil,
              let formState = state.initialCreateDeviceFormState
        else {
          return .none
        }

        state.lifecycleSheet = .create(formState)
        return .none

      case .cloneSelectedSimulatorButtonTapped:
        guard state.workspace.deviceCommandState == nil,
              let device = state.workspace.selectedDevice
        else {
          return .none
        }

        state.lifecycleSheet = .clone(
          CloneDeviceFormState(
            sourceDeviceID: device.id,
            sourceName: device.name,
            name: "\(device.name) Copy"
          )
        )
        return .none

      case .pairDevicesButtonTapped:
        guard state.workspace.deviceCommandState == nil,
              let formState = state.initialPairDevicesFormState
        else {
          return .none
        }

        state.lifecycleSheet = .pair(formState)
        return .none

      case .lifecycleSheetDismissed:
        state.lifecycleSheet = nil
        return .none

      case .createDeviceSubmitted(let formState):
        state.lifecycleSheet = nil
        return runCreateDeviceCommand(&state, formState: formState)

      case .cloneDeviceSubmitted(let formState):
        state.lifecycleSheet = nil
        return runCloneDeviceCommand(&state, formState: formState)

      case .renameDeviceSubmitted(let formState):
        state.lifecycleSheet = nil
        return runRenameDeviceCommand(&state, formState: formState)

      case .eraseDeviceConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runEraseDeviceCommand(&state, confirmationState: confirmationState)

      case .deleteDeviceConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runDeleteDeviceCommand(&state, confirmationState: confirmationState)

      case .pairDevicesSubmitted(let formState):
        state.lifecycleSheet = nil
        return runPairDevicesCommand(&state, formState: formState)

      case .unpairDeviceConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runUnpairDeviceCommand(&state, confirmationState: confirmationState)

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

      case .workspace(.deviceDetail(.renameButtonTapped(let deviceID))):
        guard state.workspace.deviceCommandState == nil,
              let device = device(id: deviceID, in: state)
        else {
          return .none
        }

        state.lifecycleSheet = .rename(
          RenameDeviceFormState(
            deviceID: device.id,
            currentName: device.name,
            name: device.name
          )
        )
        return .none

      case .workspace(.deviceDetail(.eraseButtonTapped(let deviceID))):
        guard state.workspace.deviceCommandState == nil,
              let confirmationState = deviceDestructiveConfirmationState(
                deviceID: deviceID,
                in: state
              )
        else {
          return .none
        }

        state.lifecycleSheet = .erase(confirmationState)
        return .none

      case .workspace(.deviceDetail(.deleteButtonTapped(let deviceID))):
        guard state.workspace.deviceCommandState == nil,
              let confirmationState = deviceDestructiveConfirmationState(
                deviceID: deviceID,
                in: state
              )
        else {
          return .none
        }

        state.lifecycleSheet = .delete(confirmationState)
        return .none

      case .workspace(.deviceDetail(.unpairButtonTapped(let pairID))):
        guard state.workspace.deviceCommandState == nil,
              let confirmationState = unpairConfirmationState(pairID: pairID, in: state)
        else {
          return .none
        }

        state.lifecycleSheet = .unpair(confirmationState)
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
          let deviceID = deviceCommandState.deviceID,
          let device = device(id: deviceID, in: state),
          canRun(deviceCommandState.command, on: device)
    else {
      return .none
    }

    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult: CommandResult

      switch deviceCommandState.command {
      case .boot:
        commandResult = await coreSimulatorService.bootDevice(deviceID)
      case .shutdown:
        commandResult = await coreSimulatorService.shutdownDevice(deviceID)
      case .create, .clone, .rename, .erase, .delete, .pair, .unpair:
        return
      }

      await send(.deviceCommandResponse(deviceCommandState, commandResult))
      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runCreateDeviceCommand(
    _ state: inout State,
    formState: CreateDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          let snapshot = state.workspace.snapshot,
          let runtime = snapshot.runtimes.first(where: { $0.id == formState.runtimeID && $0.isAvailable }),
          let deviceType = compatibleDeviceTypes(for: runtime, in: snapshot.deviceTypes)
            .first(where: { $0.id == formState.deviceTypeID })
    else {
      return .none
    }

    let name = nonEmpty(formState.name) ?? deviceType.name
    guard !name.isEmpty else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .create)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.createDevice(
        name,
        deviceType.id,
        runtime.id
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: Self.preferredDeviceID(from: commandResult)
        )
      )
    }
  }

  private func runCloneDeviceCommand(
    _ state: inout State,
    formState: CloneDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          device(id: formState.sourceDeviceID, in: state) != nil,
          let name = nonEmpty(formState.name)
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .clone,
      deviceID: formState.sourceDeviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.cloneDevice(
        formState.sourceDeviceID,
        name
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: Self.preferredDeviceID(from: commandResult)
        )
      )
    }
  }

  private func runRenameDeviceCommand(
    _ state: inout State,
    formState: RenameDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          device(id: formState.deviceID, in: state) != nil,
          let name = nonEmpty(formState.name),
          name != formState.currentName
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .rename,
      deviceID: formState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.renameDevice(
        formState.deviceID,
        name
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runEraseDeviceCommand(
    _ state: inout State,
    confirmationState: DeviceDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          let device = device(id: confirmationState.deviceID, in: state),
          device.isAvailable,
          device.udid == confirmationState.deviceUDID
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .erase,
      deviceID: confirmationState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.eraseDevice(confirmationState.deviceID)
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runDeleteDeviceCommand(
    _ state: inout State,
    confirmationState: DeviceDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          let device = device(id: confirmationState.deviceID, in: state),
          device.udid == confirmationState.deviceUDID
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .delete,
      deviceID: confirmationState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.deleteDevice(confirmationState.deviceID)
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runPairDevicesCommand(
    _ state: inout State,
    formState: PairDevicesFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.pairPhoneCandidates.contains(where: { $0.id == formState.phoneDeviceID }),
          state.pairWatchCandidates.contains(where: { $0.id == formState.watchDeviceID })
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .pair)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.pairDevices(
        formState.watchDeviceID,
        formState.phoneDeviceID
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runUnpairDeviceCommand(
    _ state: inout State,
    confirmationState: UnpairDeviceConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          unpairConfirmationState(pairID: confirmationState.pairID, in: state) == confirmationState
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .unpair)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.unpairDevice(confirmationState.pairID)
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
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

  private func deviceDestructiveConfirmationState(
    deviceID: String,
    in state: State
  ) -> DeviceDestructiveConfirmationState? {
    guard let device = device(id: deviceID, in: state) else {
      return nil
    }

    return DeviceDestructiveConfirmationState(
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid
    )
  }

  private func unpairConfirmationState(
    pairID: String,
    in state: State
  ) -> UnpairDeviceConfirmationState? {
    guard let snapshot = state.workspace.snapshot,
          let pair = snapshot.pairs.first(where: { $0.id == pairID }),
          let phoneDevice = snapshot.devices.first(where: { $0.id == pair.phoneDeviceID }),
          let watchDevice = snapshot.devices.first(where: { $0.id == pair.watchDeviceID })
    else {
      return nil
    }

    return UnpairDeviceConfirmationState(
      pairID: pair.id,
      phoneName: phoneDevice.name,
      phoneUDID: phoneDevice.udid,
      watchName: watchDevice.name,
      watchUDID: watchDevice.udid
    )
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
    case .create, .clone, .rename, .erase, .delete, .pair, .unpair:
      return false
    }
  }

  private func compatibleDeviceTypes(
    for runtime: SimulatorRuntime,
    in deviceTypes: [SimulatorDeviceType]
  ) -> [SimulatorDeviceType] {
    guard !runtime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }

  private func nonEmpty(_ value: String) -> String? {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }

  private static func preferredDeviceID(from result: CommandResult) -> String? {
    guard result.succeeded else {
      return nil
    }

    return result.stdout
      .split(whereSeparator: \.isNewline)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty }
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
