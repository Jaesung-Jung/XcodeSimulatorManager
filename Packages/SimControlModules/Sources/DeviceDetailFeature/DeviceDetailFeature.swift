import ComposableArchitecture
import DeveloperToolsFeature
import InstalledAppsFeature
import MainWindowFeatureSupport
import SimControlDomain

@Reducer
public struct DeviceDetailFeature {
  public init() {}

  public struct DevicePairSummary: Equatable, Identifiable {
    public let id: String
    public let phoneDeviceID: String
    public let phoneName: String
    public let phoneUDID: String
    public let watchDeviceID: String
    public let watchName: String
    public let watchUDID: String
    public let state: DevicePair.State

    public init(
      id: String,
      phoneDeviceID: String,
      phoneName: String,
      phoneUDID: String,
      watchDeviceID: String,
      watchName: String,
      watchUDID: String,
      state: DevicePair.State
    ) {
      self.id = id
      self.phoneDeviceID = phoneDeviceID
      self.phoneName = phoneName
      self.phoneUDID = phoneUDID
      self.watchDeviceID = watchDeviceID
      self.watchName = watchName
      self.watchUDID = watchUDID
      self.state = state
    }
  }

  @ObservableState
  public struct State: Equatable {
    public var device: SimulatorDevice?
    public var runtime: SimulatorRuntime?
    public var deviceType: SimulatorDeviceType?
    public var pairSummary: DevicePairSummary?
    public var installedApps: InstalledAppsFeature.State
    public var commandResults: [CommandResult]
    public var deviceCommandState: DeviceCommandState?
    public var appCommandState: AppCommandState?
    public var isOpeningSimulatorApp: Bool
    public var developerTools: DeveloperToolsFeature.State

    public init(
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

    public var selectedApp: InstalledApp? {
      guard let selectedAppID = installedApps.selectedAppID else {
        return nil
      }

      return installedApps.apps.first { $0.id == selectedAppID }
    }
  }

  public enum Action: Equatable {
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

  public var body: some ReducerOf<Self> {
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
