import ComposableArchitecture
import DeviceListFeature
import InstalledAppsFeature
import MainWindowFeatureSupport
import SimControlDomain

@Reducer
public struct WorkspaceFeature {
  @ObservableState
  public struct State: Equatable {
    var snapshot: SimulatorSnapshot?
    var refreshState: InventoryRefreshState
    var filters: SimulatorFilters
    var deviceList: DeviceListFeature.State
    var deviceDetail: DeviceDetailFeature.State
    var inspector: InspectorFeature.State
    var commandResults: [CommandResult]
    var installedAppsAvailability: InstalledAppsAvailability
    var deviceCommandState: DeviceCommandState?
    var appCommandState: AppCommandState?
    var isOpeningSimulatorApp: Bool

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      selectedDeviceID: String? = nil,
      selectedAppID: String? = nil,
      commandResults: [CommandResult] = [],
      installedAppsAvailability: InstalledAppsAvailability? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      isOpeningSimulatorApp: Bool = false,
      filters: SimulatorFilters = SimulatorFilters()
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
      self.filters = filters
      self.deviceList = DeviceListFeature.State()
      self.deviceDetail = DeviceDetailFeature.State()
      self.inspector = InspectorFeature.State(snapshot: snapshot)
      self.commandResults = commandResults
      self.installedAppsAvailability = installedAppsAvailability ?? (snapshot == nil ? .notLoaded : .loaded)
      self.deviceCommandState = deviceCommandState
      self.appCommandState = appCommandState
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
      preferredSelectedDeviceID: String? = nil,
      preferredSelectedAppID: String? = nil
    ) {
      self.snapshot = snapshot

      let selection = inventoryQuery?.selectionAfterApplyingSnapshot(
        current: SimulatorInventorySelection(
          deviceID: deviceList.selectedDeviceID,
          appID: deviceDetail.installedApps.selectedAppID
        ),
        preferred: SimulatorInventorySelection(
          deviceID: preferredSelectedDeviceID,
          appID: preferredSelectedAppID
        )
      )

      self.refreshState = refreshState
      self.commandResults = commandResults
      installedAppsAvailability = .loaded
      rebuildDeviceList(selectedDeviceID: selection?.deviceID)
      rebuildDetail(selectedAppID: selection?.appID)
    }

    mutating func selectDevice(id: String?) {
      guard deviceList.selectedDeviceID != id else {
        return
      }

      if let id {
        guard devices.contains(where: { $0.id == id }) else {
          return
        }
      }

      deviceList.selectedDeviceID = id
      rebuildDeviceList(selectedDeviceID: id)
      rebuildDetail(selectedAppID: nil)
    }

    mutating func selectApp(id: String?) {
      if let id {
        guard deviceDetail.installedApps.apps.contains(where: { $0.id == id }) else {
          return
        }

        filters.recordRecentAppID(id)
      }

      rebuildDetail(selectedAppID: id)
    }

    mutating func setSearchQuery(_ query: String) {
      filters.searchQuery = query
      let searchTarget = inventoryQuery?.exactSearchTarget()
      rebuildAfterFilterChange(
        preferredSelectedDeviceID: searchTarget?.deviceID,
        preferredSelectedAppID: searchTarget?.appID
      )
    }

    mutating func setSidebarScope(_ scope: SimulatorFilters.SidebarScope) {
      filters.sidebarScope = scope
      rebuildAfterFilterChange()
    }

    mutating func setDeviceSort(_ sort: SimulatorFilters.DeviceSort) {
      filters.deviceSort = sort
      rebuildAfterFilterChange()
    }

    mutating func setDeviceSortDirection(_ direction: SimulatorFilters.SortDirection) {
      filters.deviceSortDirection = direction
      rebuildAfterFilterChange()
    }

    mutating func setAppSystemFilter(_ filter: SimulatorFilters.AppSystemFilter) {
      filters.appSystemFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setAppGroupFilter(_ filter: SimulatorFilters.PresenceFilter) {
      filters.appGroupFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setAppDatabaseFilter(_ filter: SimulatorFilters.PresenceFilter) {
      filters.appDatabaseFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setAppSort(_ sort: SimulatorFilters.AppSort) {
      filters.appSort = sort
      rebuildAfterFilterChange()
    }

    mutating func setAppSortDirection(_ direction: SimulatorFilters.SortDirection) {
      filters.appSortDirection = direction
      rebuildAfterFilterChange()
    }

    mutating func clearAppFilters() {
      filters.appSystemFilter = .user
      filters.appGroupFilter = .all
      filters.appDatabaseFilter = .all
      rebuildAfterFilterChange()
    }

    mutating func togglePinnedDevice(id: String) {
      if filters.pinnedDeviceIDs.contains(id) {
        filters.pinnedDeviceIDs.remove(id)
      } else {
        filters.pinnedDeviceIDs.insert(id)
      }

      rebuildAfterFilterChange(preferredSelectedDeviceID: id)
    }

    mutating func togglePinnedApp(id: String) {
      if filters.pinnedAppIDs.contains(id) {
        filters.pinnedAppIDs.remove(id)
      } else {
        filters.pinnedAppIDs.insert(id)
      }

      rebuildAfterFilterChange(preferredSelectedAppID: id)
    }

    mutating func appendCommandResult(_ result: CommandResult) {
      commandResults.append(result)
      deviceDetail.commandResults = commandResults
    }

    mutating func setDeviceCommandState(_ deviceCommandState: DeviceCommandState?) {
      self.deviceCommandState = deviceCommandState
      deviceDetail.deviceCommandState = deviceCommandState
      deviceDetail.installedApps.isDeviceCommandRunning = deviceCommandState != nil
      deviceDetail.developerTools.deviceCommandState = deviceCommandState
    }

    mutating func setAppCommandState(_ appCommandState: AppCommandState?) {
      self.appCommandState = appCommandState
      deviceDetail.appCommandState = appCommandState
      deviceDetail.installedApps.appCommandState = appCommandState
      deviceDetail.developerTools.appCommandState = appCommandState
    }

    mutating func setOpeningSimulatorApp(_ isOpeningSimulatorApp: Bool) {
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
      deviceDetail.isOpeningSimulatorApp = isOpeningSimulatorApp
    }

    private mutating func rebuildDeviceList(selectedDeviceID: String?) {
      deviceList = DeviceListFeature.State(
        devices: inventoryQuery?.visibleDevices() ?? [],
        runtimeByID: inventoryQuery?.runtimeByID ?? [:],
        deviceTypeByID: inventoryQuery?.deviceTypeByID ?? [:],
        installedAppsByDeviceID: inventoryQuery?.visibleInstalledAppsByDeviceID() ?? [:],
        installedAppsAvailability: installedAppsAvailability,
        selectedDeviceID: selectedDeviceID,
        filters: filters,
        totalDeviceCount: devices.count
      )
    }

    private mutating func rebuildDetail(selectedAppID: String?) {
      let allInstalledApps = selectedDevice.map { device in
        snapshot?.installedAppsByDeviceID[device.id] ?? []
      } ?? []
      let installedApps = selectedDevice.map {
        inventoryQuery?.visibleApps(for: $0.id) ?? []
      } ?? []
      var developerTools = deviceDetail.developerTools
      developerTools.updateContext(
        device: selectedDevice,
        installedApps: allInstalledApps,
        selectedAppID: selectedAppID,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState
      )

      deviceDetail = DeviceDetailFeature.State(
        device: selectedDevice,
        runtime: selectedRuntime,
        deviceType: selectedDeviceType,
        pairSummary: selectedPairSummary,
        installedApps: InstalledAppsFeature.State(
          apps: installedApps,
          availability: installedAppsAvailability,
          device: selectedDevice,
          selectedAppID: selectedAppID,
          appCommandState: appCommandState,
          isDeviceCommandRunning: deviceCommandState != nil,
          compatibleInstallTargetCount: inventoryQuery?.compatibleInstallTargetCount(for: selectedDevice) ?? 0,
          filters: filters,
          allAppsCount: allInstalledApps.count
        ),
        commandResults: commandResults,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp,
        developerTools: developerTools
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

    private mutating func rebuildAfterFilterChange(
      preferredSelectedDeviceID: String? = nil,
      preferredSelectedAppID: String? = nil
    ) {
      let selection = inventoryQuery?.selectionAfterFilterChange(
        current: SimulatorInventorySelection(
          deviceID: deviceList.selectedDeviceID,
          appID: deviceDetail.installedApps.selectedAppID
        ),
        preferred: SimulatorInventorySelection(
          deviceID: preferredSelectedDeviceID,
          appID: preferredSelectedAppID
        )
      )

      rebuildDeviceList(selectedDeviceID: selection?.deviceID)
      rebuildDetail(selectedAppID: selection?.appID)
    }

    private var inventoryQuery: SimulatorInventoryQuery? {
      guard let snapshot else {
        return nil
      }

      return SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
    }

    private var devices: [SimulatorDevice] {
      inventoryQuery?.devices ?? []
    }

    private var runtimeByID: [String: SimulatorRuntime] {
      inventoryQuery?.runtimeByID ?? [:]
    }

    private var deviceTypeByID: [String: SimulatorDeviceType] {
      inventoryQuery?.deviceTypeByID ?? [:]
    }

    var selectedDevice: SimulatorDevice? {
      inventoryQuery?.device(id: deviceList.selectedDeviceID)
    }

    var selectedRuntime: SimulatorRuntime? {
      inventoryQuery?.runtime(for: selectedDevice)
    }

    var selectedDeviceType: SimulatorDeviceType? {
      inventoryQuery?.deviceType(for: selectedDevice)
    }

    var selectedPairSummary: DeviceDetailFeature.DevicePairSummary? {
      guard let summary = inventoryQuery?.pairSummary(for: selectedDevice) else {
        return nil
      }

      return DeviceDetailFeature.DevicePairSummary(
        id: summary.id,
        phoneDeviceID: summary.phoneDeviceID,
        phoneName: summary.phoneName,
        phoneUDID: summary.phoneUDID,
        watchDeviceID: summary.watchDeviceID,
        watchName: summary.watchName,
        watchUDID: summary.watchUDID,
        state: summary.state
      )
    }
  }

  public enum Action: Equatable {
    case searchQueryChanged(String)
    case sidebarScopeChanged(SimulatorFilters.SidebarScope)
    case deviceList(DeviceListFeature.Action)
    case deviceDetail(DeviceDetailFeature.Action)
    case inspector(InspectorFeature.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .searchQueryChanged(let query):
        state.setSearchQuery(query)
        return .none

      case .sidebarScopeChanged(let scope):
        state.setSidebarScope(scope)
        return .none

      case .deviceList(.selectionChanged(let id)):
        state.selectDevice(id: id)
        return .none

      case .deviceList(.pinButtonTapped(let id)):
        state.togglePinnedDevice(id: id)
        return .none

      case .deviceList(.deviceSortChanged(let sort)):
        state.setDeviceSort(sort)
        return .none

      case .deviceList(.deviceSortDirectionChanged(let direction)):
        state.setDeviceSortDirection(direction)
        return .none

      case .deviceDetail(.installedApps(.selectionChanged(let id))):
        state.selectApp(id: id)
        return .none

      case .deviceDetail(.installedApps(.pinButtonTapped(let id))):
        state.togglePinnedApp(id: id)
        return .none

      case .deviceDetail(.installedApps(.appSystemFilterChanged(let filter))):
        state.setAppSystemFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appGroupFilterChanged(let filter))):
        state.setAppGroupFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appDatabaseFilterChanged(let filter))):
        state.setAppDatabaseFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appSortChanged(let sort))):
        state.setAppSort(sort)
        return .none

      case .deviceDetail(.installedApps(.appSortDirectionChanged(let direction))):
        state.setAppSortDirection(direction)
        return .none

      case .deviceDetail(.installedApps(.clearAppFiltersButtonTapped)):
        state.clearAppFilters()
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
