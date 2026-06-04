import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

/// Coordinates device list selection, sorting, and pin commands.
@Reducer
public struct DeviceListFeature {
  /// Creates the device list reducer.
  public init() {}

  /// State projected into the simulator device list.
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

    /// Creates device list state from visible devices, lookup tables, selection, and filters.
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

  /// User actions emitted by the device list UI.
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
