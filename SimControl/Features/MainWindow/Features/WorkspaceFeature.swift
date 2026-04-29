import ComposableArchitecture

@Reducer
struct WorkspaceFeature {
  @ObservableState
  struct State: Equatable {
    var snapshot: SimulatorSnapshot?
    var refreshState: InventoryRefreshState
    var deviceList: DeviceListFeature.State
    var deviceDetail: DeviceDetailFeature.State
    var inspector: InspectorFeature.State
    var commandResults: [CommandResult]
    var installedAppsAvailability: InstalledAppsAvailability
    var deviceCommandState: DeviceCommandState?
    var isOpeningSimulatorApp: Bool

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      selectedDeviceID: String? = nil,
      selectedAppID: String? = nil,
      commandResults: [CommandResult] = [],
      installedAppsAvailability: InstalledAppsAvailability? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      isOpeningSimulatorApp: Bool = false
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
      self.deviceList = DeviceListFeature.State()
      self.deviceDetail = DeviceDetailFeature.State()
      self.inspector = InspectorFeature.State(snapshot: snapshot)
      self.commandResults = commandResults
      self.installedAppsAvailability = installedAppsAvailability ?? (snapshot == nil ? .notLoaded : .loaded)
      self.deviceCommandState = deviceCommandState
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
      rebuildDeviceList(selectedDeviceID: selectedDeviceID)
      rebuildDetail(selectedAppID: selectedAppID)
    }

    mutating func setRefreshState(_ refreshState: InventoryRefreshState) {
      self.refreshState = refreshState
    }

    mutating func applyRefreshFailure(
      _ refreshState: InventoryRefreshState,
      commandResults: [CommandResult]
    ) {
      self.refreshState = refreshState
      self.commandResults = commandResults
      deviceDetail.commandResults = commandResults
    }

    mutating func applySnapshot(
      _ snapshot: SimulatorSnapshot,
      refreshState: InventoryRefreshState,
      commandResults: [CommandResult],
      preferredSelectedDeviceID: String? = nil
    ) {
      let previousSelectedDeviceID = deviceList.selectedDeviceID
      let selectedDeviceID = validPreferredSelectedDeviceID(preferredSelectedDeviceID, in: snapshot) ?? validSelectedDeviceID(in: snapshot)
      let selectedAppID = selectedDeviceID == previousSelectedDeviceID ? deviceDetail.installedApps.selectedAppID : nil

      self.snapshot = snapshot
      self.refreshState = refreshState
      self.commandResults = commandResults
      installedAppsAvailability = .loaded
      rebuildDeviceList(selectedDeviceID: selectedDeviceID)
      rebuildDetail(selectedAppID: selectedAppID)
    }

    mutating func selectDevice(id: String?) {
      guard deviceList.selectedDeviceID != id else {
        return
      }

      deviceList.selectedDeviceID = id
      rebuildDetail(selectedAppID: nil)
    }

    mutating func selectApp(id: String?) {
      deviceDetail.installedApps.selectedAppID = id
      rebuildInspector()
    }

    mutating func appendCommandResult(_ result: CommandResult) {
      commandResults.append(result)
      deviceDetail.commandResults = commandResults
    }

    mutating func setDeviceCommandState(_ deviceCommandState: DeviceCommandState?) {
      self.deviceCommandState = deviceCommandState
      deviceDetail.deviceCommandState = deviceCommandState
    }

    mutating func setOpeningSimulatorApp(_ isOpeningSimulatorApp: Bool) {
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
      deviceDetail.isOpeningSimulatorApp = isOpeningSimulatorApp
    }

    private mutating func rebuildDeviceList(selectedDeviceID: String?) {
      deviceList = DeviceListFeature.State(
        devices: devices,
        runtimeByID: runtimeByID,
        deviceTypeByID: deviceTypeByID,
        installedAppsByDeviceID: snapshot?.installedAppsByDeviceID ?? [:],
        installedAppsAvailability: installedAppsAvailability,
        selectedDeviceID: selectedDeviceID
      )
    }

    private mutating func rebuildDetail(selectedAppID: String?) {
      let installedApps = selectedDevice.map { device in
        snapshot?.installedAppsByDeviceID[device.id] ?? []
      } ?? []

      deviceDetail = DeviceDetailFeature.State(
        device: selectedDevice,
        runtime: selectedRuntime,
        deviceType: selectedDeviceType,
        pairSummary: selectedPairSummary,
        installedApps: InstalledAppsFeature.State(
          apps: installedApps,
          availability: installedAppsAvailability,
          selectedAppID: selectedAppID
        ),
        commandResults: commandResults,
        deviceCommandState: deviceCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp
      )
      rebuildInspector()
    }

    private mutating func rebuildInspector() {
      inspector = InspectorFeature.State(
        snapshot: snapshot,
        device: selectedDevice,
        runtime: selectedRuntime,
        deviceType: selectedDeviceType,
        selectedApp: deviceDetail.selectedApp
      )
    }

    private func validSelectedDeviceID(in snapshot: SimulatorSnapshot) -> String? {
      guard let selectedDeviceID = deviceList.selectedDeviceID else {
        return nil
      }

      return snapshot.devices.contains(where: { $0.id == selectedDeviceID })
        ? selectedDeviceID
        : nil
    }

    private func validPreferredSelectedDeviceID(
      _ preferredSelectedDeviceID: String?,
      in snapshot: SimulatorSnapshot
    ) -> String? {
      guard let preferredSelectedDeviceID else {
        return nil
      }

      return snapshot.devices.contains(where: { $0.id == preferredSelectedDeviceID })
        ? preferredSelectedDeviceID
        : nil
    }

    private var devices: [SimulatorDevice] {
      snapshot?.devices ?? []
    }

    private var runtimeByID: [String: SimulatorRuntime] {
      Dictionary(uniqueKeysWithValues: (snapshot?.runtimes ?? []).map { ($0.id, $0) })
    }

    private var deviceTypeByID: [String: SimulatorDeviceType] {
      Dictionary(uniqueKeysWithValues: (snapshot?.deviceTypes ?? []).map { ($0.id, $0) })
    }

    private var deviceByID: [String: SimulatorDevice] {
      Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
    }

    var selectedDevice: SimulatorDevice? {
      guard let selectedDeviceID = deviceList.selectedDeviceID else {
        return nil
      }

      return devices.first { $0.id == selectedDeviceID }
    }

    var selectedRuntime: SimulatorRuntime? {
      guard let selectedDevice else {
        return nil
      }

      return runtimeByID[selectedDevice.runtimeID]
    }

    var selectedDeviceType: SimulatorDeviceType? {
      guard let selectedDevice else {
        return nil
      }

      return deviceTypeByID[selectedDevice.deviceTypeID]
    }

    var selectedPairSummary: DeviceDetailFeature.DevicePairSummary? {
      guard let selectedDevice, let snapshot else {
        return nil
      }

      let selectedDeviceID = selectedDevice.id
      guard let pair = snapshot.pairs.first(where: {
        $0.phoneDeviceID == selectedDeviceID || $0.watchDeviceID == selectedDeviceID
      }),
        let phoneDevice = deviceByID[pair.phoneDeviceID],
        let watchDevice = deviceByID[pair.watchDeviceID]
      else {
        return nil
      }

      return DeviceDetailFeature.DevicePairSummary(
        id: pair.id,
        phoneDeviceID: phoneDevice.id,
        phoneName: phoneDevice.name,
        phoneUDID: phoneDevice.udid,
        watchDeviceID: watchDevice.id,
        watchName: watchDevice.name,
        watchUDID: watchDevice.udid,
        state: pair.state
      )
    }
  }

  enum Action: Equatable {
    case deviceList(DeviceListFeature.Action)
    case deviceDetail(DeviceDetailFeature.Action)
    case inspector(InspectorFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .deviceList(.selectionChanged(let id)):
        state.selectDevice(id: id)
        return .none

      case .deviceDetail(.installedApps(.selectionChanged(let id))):
        state.selectApp(id: id)
        return .none

      case .deviceDetail, .inspector:
        return .none
      }
    }

    Scope(state: \.deviceList, action: \.deviceList) {
      DeviceListFeature()
    }
    Scope(state: \.deviceDetail, action: \.deviceDetail) {
      DeviceDetailFeature()
    }
    Scope(state: \.inspector, action: \.inspector) {
      InspectorFeature()
    }
  }
}
