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

    init(
      devices: [SimulatorDevice] = [],
      runtimeByID: [String: SimulatorRuntime] = [:],
      deviceTypeByID: [String: SimulatorDeviceType] = [:],
      installedAppsByDeviceID: [String: [InstalledApp]] = [:],
      installedAppsAvailability: InstalledAppsAvailability = .notLoaded,
      selectedDeviceID: String? = nil
    ) {
      self.devices = devices
      self.runtimeByID = runtimeByID
      self.deviceTypeByID = deviceTypeByID
      self.installedAppsByDeviceID = installedAppsByDeviceID
      self.installedAppsAvailability = installedAppsAvailability
      self.selectedDeviceID = selectedDeviceID
    }
  }

  enum Action: Equatable {
    case selectionChanged(String?)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .selectionChanged(let id):
        state.selectedDeviceID = id
        return .none
      }
    }
  }
}
