import ComposableArchitecture
import SimControlDomain

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
    var appCommandState: AppCommandState?
    var isOpeningSimulatorApp: Bool
    var developerTools: DeveloperToolsFeature.State

    init(
      device: SimulatorDevice? = nil,
      runtime: SimulatorRuntime? = nil,
      deviceType: SimulatorDeviceType? = nil,
      pairSummary: DevicePairSummary? = nil,
      installedApps: InstalledAppsFeature.State = InstalledAppsFeature.State(),
      commandResults: [CommandResult] = [],
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      isOpeningSimulatorApp: Bool = false,
      developerTools: DeveloperToolsFeature.State = DeveloperToolsFeature.State()
    ) {
      var installedApps = installedApps
      installedApps.appCommandState = appCommandState
      installedApps.isDeviceCommandRunning = deviceCommandState != nil
      var developerTools = developerTools
      developerTools.updateContext(
        device: device,
        installedApps: installedApps.apps,
        selectedAppID: installedApps.selectedAppID,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState
      )

      self.device = device
      self.runtime = runtime
      self.deviceType = deviceType
      self.pairSummary = pairSummary
      self.installedApps = installedApps
      self.commandResults = commandResults
      self.deviceCommandState = deviceCommandState
      self.appCommandState = appCommandState
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
      self.developerTools = developerTools
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
    case openDeviceDataFolderButtonTapped(String)
    case copyDeviceDataPathButtonTapped(String)
    case openDeviceLogFolderButtonTapped(String)
    case copyDeviceLogPathButtonTapped(String)
    case copyDeviceUDIDButtonTapped(String)
    case copyRuntimeIdentifierButtonTapped(String)
    case copyDeviceTypeIdentifierButtonTapped(String)
    case installedApps(InstalledAppsFeature.Action)
    case developerTools(DeveloperToolsFeature.Action)
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
           .unpairButtonTapped,
           .openDeviceDataFolderButtonTapped,
           .copyDeviceDataPathButtonTapped,
           .openDeviceLogFolderButtonTapped,
           .copyDeviceLogPathButtonTapped,
           .copyDeviceUDIDButtonTapped,
           .copyRuntimeIdentifierButtonTapped,
           .copyDeviceTypeIdentifierButtonTapped:
        return .none

      case .installedApps:
        return .none

      case .developerTools:
        return .none
      }
    }

    Scope(state: \.installedApps, action: \.installedApps) {
      InstalledAppsFeature()
    }
    Scope(state: \.developerTools, action: \.developerTools) {
      DeveloperToolsFeature()
    }
  }
}
