import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

@Reducer
public struct DeviceListFeature {
  public init() {}

  @ObservableState
  public struct State: Equatable {
    public var devices: [SimulatorDevice]
    public var runtimeByID: [String: SimulatorRuntime]
    public var deviceTypeByID: [String: SimulatorDeviceType]
    public var installedAppsByDeviceID: [String: [InstalledApp]]
    public var installedAppsAvailability: InstalledAppsAvailability
    public var selectedDeviceID: String?
    public var filters: SimulatorFilters
    public var totalDeviceCount: Int

    public init(
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

  public enum Action: Equatable {
    case selectionChanged(String?)
    case pinButtonTapped(String)
    case deviceSortChanged(SimulatorFilters.DeviceSort)
    case deviceSortDirectionChanged(SimulatorFilters.SortDirection)
  }

  public var body: some ReducerOf<Self> {
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
