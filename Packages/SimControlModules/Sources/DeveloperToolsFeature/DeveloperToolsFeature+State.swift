import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - DeveloperToolsFeature.State

extension DeveloperToolsFeature {
  @ObservableState
  public struct State: Equatable {
    public var device: SimulatorDevice?
    public var installedApps: [InstalledApp]
    public var selectedAppID: String?
    public var deviceCommandState: DeviceCommandState?
    public var appCommandState: AppCommandState?
    public var deepLinkURLString: String
    public var recentDeepLinkURLs: [String]
    public var pushBundleID: String
    public var pushPayloadJSON: String
    public var privacyAction: PrivacyAction
    public var privacyService: PrivacyService
    public var privacyBundleID: String
    public var locationPreset: LocationPreset
    public var customLatitude: String
    public var customLongitude: String
    public var recentLocations: [LocationCoordinateInput]
    public var statusBarTime: String
    public var statusBarDataNetwork: StatusBarDataNetwork?
    public var statusBarWifiMode: StatusBarWifiMode?
    public var statusBarWifiBars: String
    public var statusBarCellularMode: StatusBarCellularMode?
    public var statusBarCellularBars: String
    public var statusBarOperatorNameIncluded: Bool
    public var statusBarOperatorName: String
    public var statusBarBatteryState: StatusBarBatteryState?
    public var statusBarBatteryLevel: String

    public init(
      device: SimulatorDevice? = nil,
      installedApps: [InstalledApp] = [],
      selectedAppID: String? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      deepLinkURLString: String = "",
      recentDeepLinkURLs: [String] = [],
      pushBundleID: String = "",
      pushPayloadJSON: String = Self.defaultPushPayloadJSON,
      privacyAction: PrivacyAction = .grant,
      privacyService: PrivacyService = .location,
      privacyBundleID: String = "",
      locationPreset: LocationPreset = .applePark,
      customLatitude: String = "",
      customLongitude: String = "",
      recentLocations: [LocationCoordinateInput] = [],
      statusBarTime: String = "",
      statusBarDataNetwork: StatusBarDataNetwork? = nil,
      statusBarWifiMode: StatusBarWifiMode? = nil,
      statusBarWifiBars: String = "",
      statusBarCellularMode: StatusBarCellularMode? = nil,
      statusBarCellularBars: String = "",
      statusBarOperatorNameIncluded: Bool = false,
      statusBarOperatorName: String = "",
      statusBarBatteryState: StatusBarBatteryState? = nil,
      statusBarBatteryLevel: String = ""
    ) {
      self.device = device
      self.installedApps = installedApps
      self.selectedAppID = selectedAppID
      self.deviceCommandState = deviceCommandState
      self.appCommandState = appCommandState
      self.deepLinkURLString = deepLinkURLString
      self.recentDeepLinkURLs = recentDeepLinkURLs
      self.pushBundleID = pushBundleID
      self.pushPayloadJSON = pushPayloadJSON
      self.privacyAction = privacyAction
      self.privacyService = privacyService
      self.privacyBundleID = privacyBundleID
      self.locationPreset = locationPreset
      self.customLatitude = customLatitude
      self.customLongitude = customLongitude
      self.recentLocations = recentLocations
      self.statusBarTime = statusBarTime
      self.statusBarDataNetwork = statusBarDataNetwork
      self.statusBarWifiMode = statusBarWifiMode
      self.statusBarWifiBars = statusBarWifiBars
      self.statusBarCellularMode = statusBarCellularMode
      self.statusBarCellularBars = statusBarCellularBars
      self.statusBarOperatorNameIncluded = statusBarOperatorNameIncluded
      self.statusBarOperatorName = statusBarOperatorName
      self.statusBarBatteryState = statusBarBatteryState
      self.statusBarBatteryLevel = statusBarBatteryLevel
      applySelectedAppBundleIfNeeded()
    }

    mutating func applySelectedAppBundleIfNeeded() {
      guard let selectedAppBundleID else {
        return
      }

      if Self.trimmed(pushBundleID).isEmpty {
        pushBundleID = selectedAppBundleID
      }

      if Self.trimmed(privacyBundleID).isEmpty {
        privacyBundleID = selectedAppBundleID
      }
    }
  }
}
