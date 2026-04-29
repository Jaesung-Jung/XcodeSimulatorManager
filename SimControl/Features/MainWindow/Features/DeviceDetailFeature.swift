import ComposableArchitecture

@Reducer
struct DeviceDetailFeature {
  @ObservableState
  struct State: Equatable {
    var device: SimulatorDevice?
    var runtime: SimulatorRuntime?
    var deviceType: SimulatorDeviceType?
    var installedApps: InstalledAppsFeature.State
    var commandResults: [CommandResult]

    init(
      device: SimulatorDevice? = nil,
      runtime: SimulatorRuntime? = nil,
      deviceType: SimulatorDeviceType? = nil,
      installedApps: InstalledAppsFeature.State = InstalledAppsFeature.State(),
      commandResults: [CommandResult] = []
    ) {
      self.device = device
      self.runtime = runtime
      self.deviceType = deviceType
      self.installedApps = installedApps
      self.commandResults = commandResults
    }

    var selectedApp: InstalledApp? {
      guard let selectedAppID = installedApps.selectedAppID else {
        return nil
      }

      return installedApps.apps.first { $0.id == selectedAppID }
    }
  }

  enum Action: Equatable {
    case installedApps(InstalledAppsFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .installedApps:
        return .none
      }
    }

    Scope(state: \.installedApps, action: \.installedApps) {
      InstalledAppsFeature()
    }
  }
}
