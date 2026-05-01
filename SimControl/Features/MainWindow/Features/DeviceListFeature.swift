import ComposableArchitecture

@Reducer
struct DeviceListFeature {
  @ObservableState
  struct State: Equatable {
    var devices: [SimulatorDevice]
    var runtimeByID: [String: SimulatorRuntime]
    var deviceTypeByID: [String: SimulatorDeviceType]
    var installedAppsByDeviceID: [String: [InstalledApp]]
    var installedAppsAvailability: InstalledAppsAvailability
    var selectedDeviceID: String?
    var filters: SimulatorFilters
    var totalDeviceCount: Int

    init(
      devices: [SimulatorDevice] = [],
      runtimeByID: [String: SimulatorRuntime] = [:],
      deviceTypeByID: [String: SimulatorDeviceType] = [:],
      installedAppsByDeviceID: [String: [InstalledApp]] = [:],
      installedAppsAvailability: InstalledAppsAvailability = .notLoaded,
      selectedDeviceID: String? = nil,
      filters: SimulatorFilters = SimulatorFilters(),
      totalDeviceCount: Int? = nil
    ) {
      self.devices = devices
      self.runtimeByID = runtimeByID
      self.deviceTypeByID = deviceTypeByID
      self.installedAppsByDeviceID = installedAppsByDeviceID
      self.installedAppsAvailability = installedAppsAvailability
      self.selectedDeviceID = selectedDeviceID
      self.filters = filters
      self.totalDeviceCount = totalDeviceCount ?? devices.count
    }
  }

  enum Action: Equatable {
    case selectionChanged(String?)
    case pinButtonTapped(String)
    case deviceSortChanged(SimulatorFilters.DeviceSort)
    case deviceSortDirectionChanged(SimulatorFilters.SortDirection)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectionChanged(let id):
        state.selectedDeviceID = id
        return .none

      case .pinButtonTapped,
           .deviceSortChanged,
           .deviceSortDirectionChanged:
        return .none
      }
    }
  }
}
