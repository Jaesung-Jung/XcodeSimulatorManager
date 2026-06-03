import ComposableArchitecture
import SimControlDomain

@Reducer
public struct InspectorFeature {
  @ObservableState
  public struct State: Equatable {
    var snapshot: SimulatorSnapshot?
    var device: SimulatorDevice?
    var runtime: SimulatorRuntime?
    var deviceType: SimulatorDeviceType?
    var selectedApp: InstalledApp?

    init(
      snapshot: SimulatorSnapshot? = nil,
      device: SimulatorDevice? = nil,
      runtime: SimulatorRuntime? = nil,
      deviceType: SimulatorDeviceType? = nil,
      selectedApp: InstalledApp? = nil
    ) {
      self.snapshot = snapshot
      self.device = device
      self.runtime = runtime
      self.deviceType = deviceType
      self.selectedApp = selectedApp
    }
  }

  public enum Action: Equatable {
    case openDeviceDataFolderButtonTapped(String)
    case copyDeviceDataPathButtonTapped(String)
    case openDeviceLogFolderButtonTapped(String)
    case copyDeviceLogPathButtonTapped(String)
    case copyDeviceUDIDButtonTapped(String)
    case copyRuntimeIdentifierButtonTapped(String)
    case copyDeviceTypeIdentifierButtonTapped(String)
    case openAppBundleContainerButtonTapped(String)
    case copyAppBundleContainerButtonTapped(String)
    case openAppDataContainerButtonTapped(String)
    case copyAppDataContainerButtonTapped(String)
    case copyAppBundleIDButtonTapped(String)
    case openAppGroupContainerButtonTapped(String, String)
    case copyAppGroupContainerButtonTapped(String, String)
  }

  public var body: some ReducerOf<Self> {
    Reduce { _, _ in
      .none
    }
  }
}
