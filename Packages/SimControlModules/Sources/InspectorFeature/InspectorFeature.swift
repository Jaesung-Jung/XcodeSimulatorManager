import ComposableArchitecture
import SimControlDomain

/// Coordinates inspector actions for the selected device and app context.
@Reducer
public struct InspectorFeature {
  /// Creates the inspector reducer.
  public init() {}

  /// State displayed in the inspector pane.
  @ObservableState
  public struct State: Equatable {
    public var snapshot: SimulatorSnapshot?
    public var device: SimulatorDevice?
    public var runtime: SimulatorRuntime?
    public var deviceType: SimulatorDeviceType?
    public var selectedApp: InstalledApp?

    /// Creates inspector state from the current simulator and app selection context.
    public init(
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

  /// User actions emitted by inspector controls.
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
