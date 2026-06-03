import ComposableArchitecture
import DeviceDetailFeature
import DeviceListFeature
import InspectorFeature
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - WorkspaceFeature.State

extension WorkspaceFeature {
  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var refreshState: InventoryRefreshState
    public var filters: SimulatorFilters
    public var deviceList: DeviceListFeature.State
    public var deviceDetail: DeviceDetailFeature.State
    public var inspector: InspectorFeature.State
    public var commandResults: [CommandResult]
    public var installedAppsAvailability: InstalledAppsAvailability
    public var deviceCommandState: DeviceCommandState?
    public var appCommandState: AppCommandState?
    public var isOpeningSimulatorApp: Bool

    public init(
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
  }
}
