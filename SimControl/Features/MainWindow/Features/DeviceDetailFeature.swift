import ComposableArchitecture

@Reducer
struct DeviceDetailFeature {
  struct DevicePairSummary: Equatable, Identifiable {
    let id: String
    let phoneDeviceID: String
    let phoneName: String
    let phoneUDID: String
    let watchDeviceID: String
    let watchName: String
    let watchUDID: String
    let state: DevicePair.State
  }

  @ObservableState
  struct State: Equatable {
    var device: SimulatorDevice?
    var runtime: SimulatorRuntime?
    var deviceType: SimulatorDeviceType?
    var pairSummary: DevicePairSummary?
    var installedApps: InstalledAppsFeature.State
    var commandResults: [CommandResult]
    var deviceCommandState: DeviceCommandState?
    var isOpeningSimulatorApp: Bool

    init(
      device: SimulatorDevice? = nil,
      runtime: SimulatorRuntime? = nil,
      deviceType: SimulatorDeviceType? = nil,
      pairSummary: DevicePairSummary? = nil,
      installedApps: InstalledAppsFeature.State = InstalledAppsFeature.State(),
      commandResults: [CommandResult] = [],
      deviceCommandState: DeviceCommandState? = nil,
      isOpeningSimulatorApp: Bool = false
    ) {
      self.device = device
      self.runtime = runtime
      self.deviceType = deviceType
      self.pairSummary = pairSummary
      self.installedApps = installedApps
      self.commandResults = commandResults
      self.deviceCommandState = deviceCommandState
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
    }

    var selectedApp: InstalledApp? {
      guard let selectedAppID = installedApps.selectedAppID else {
        return nil
      }

      return installedApps.apps.first { $0.id == selectedAppID }
    }
  }

  enum Action: Equatable {
    case bootButtonTapped(String)
    case shutdownButtonTapped(String)
    case openSimulatorAppButtonTapped
    case renameButtonTapped(String)
    case eraseButtonTapped(String)
    case deleteButtonTapped(String)
    case unpairButtonTapped(String)
    case installedApps(InstalledAppsFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { _, action in
      switch action {
      case .bootButtonTapped,
           .shutdownButtonTapped,
           .openSimulatorAppButtonTapped,
           .renameButtonTapped,
           .eraseButtonTapped,
           .deleteButtonTapped,
           .unpairButtonTapped:
        return .none

      case .installedApps:
        return .none
      }
    }

    Scope(state: \.installedApps, action: \.installedApps) {
      InstalledAppsFeature()
    }
  }
}
