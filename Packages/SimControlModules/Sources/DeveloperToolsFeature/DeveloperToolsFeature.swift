import ComposableArchitecture

@Reducer
public struct DeveloperToolsFeature {
  public init() {}

  public enum Action: Equatable {
    case deepLinkURLChanged(String)
    case recentDeepLinkURLSelected(String)
    case openDeepLinkButtonTapped
    case pushBundleIDChanged(String)
    case pushPayloadJSONChanged(String)
    case sendPushButtonTapped
    case privacyActionChanged(PrivacyAction)
    case privacyServiceChanged(PrivacyService)
    case privacyBundleIDChanged(String)
    case useSelectedAppBundleButtonTapped
    case applyPrivacyButtonTapped
    case locationPresetChanged(LocationPreset)
    case customLatitudeChanged(String)
    case customLongitudeChanged(String)
    case recentLocationSelected(LocationCoordinateInput)
    case setLocationButtonTapped
    case clearLocationButtonTapped
    case statusBarTimeChanged(String)
    case statusBarDataNetworkChanged(StatusBarDataNetwork?)
    case statusBarWifiModeChanged(StatusBarWifiMode?)
    case statusBarWifiBarsChanged(String)
    case statusBarCellularModeChanged(StatusBarCellularMode?)
    case statusBarCellularBarsChanged(String)
    case statusBarOperatorNameIncludedChanged(Bool)
    case statusBarOperatorNameChanged(String)
    case statusBarBatteryStateChanged(StatusBarBatteryState?)
    case statusBarBatteryLevelChanged(String)
    case setStatusBarOverrideButtonTapped
    case clearStatusBarOverrideButtonTapped
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .deepLinkURLChanged(let urlString):
        state.deepLinkURLString = urlString
        return .none

      case .recentDeepLinkURLSelected(let urlString):
        state.deepLinkURLString = urlString
        return .none

      case .pushBundleIDChanged(let bundleID):
        state.pushBundleID = bundleID
        return .none

      case .pushPayloadJSONChanged(let payloadJSON):
        state.pushPayloadJSON = payloadJSON
        return .none

      case .privacyActionChanged(let privacyAction):
        state.privacyAction = privacyAction
        return .none

      case .privacyServiceChanged(let privacyService):
        state.privacyService = privacyService
        return .none

      case .privacyBundleIDChanged(let bundleID):
        state.privacyBundleID = bundleID
        return .none

      case .useSelectedAppBundleButtonTapped:
        state.applySelectedAppBundle()
        return .none

      case .locationPresetChanged(let locationPreset):
        state.locationPreset = locationPreset
        return .none

      case .customLatitudeChanged(let latitude):
        state.customLatitude = latitude
        return .none

      case .customLongitudeChanged(let longitude):
        state.customLongitude = longitude
        return .none

      case .recentLocationSelected(let location):
        state.locationPreset = .custom
        state.customLatitude = location.latitude
        state.customLongitude = location.longitude
        return .none

      case .statusBarTimeChanged(let time):
        state.statusBarTime = time
        return .none

      case .statusBarDataNetworkChanged(let dataNetwork):
        state.statusBarDataNetwork = dataNetwork
        return .none

      case .statusBarWifiModeChanged(let wifiMode):
        state.statusBarWifiMode = wifiMode
        return .none

      case .statusBarWifiBarsChanged(let wifiBars):
        state.statusBarWifiBars = wifiBars
        return .none

      case .statusBarCellularModeChanged(let cellularMode):
        state.statusBarCellularMode = cellularMode
        return .none

      case .statusBarCellularBarsChanged(let cellularBars):
        state.statusBarCellularBars = cellularBars
        return .none

      case .statusBarOperatorNameIncludedChanged(let isIncluded):
        state.statusBarOperatorNameIncluded = isIncluded
        return .none

      case .statusBarOperatorNameChanged(let operatorName):
        state.statusBarOperatorName = operatorName
        return .none

      case .statusBarBatteryStateChanged(let batteryState):
        state.statusBarBatteryState = batteryState
        return .none

      case .statusBarBatteryLevelChanged(let batteryLevel):
        state.statusBarBatteryLevel = batteryLevel
        return .none

      case .openDeepLinkButtonTapped,
           .sendPushButtonTapped,
           .applyPrivacyButtonTapped,
           .setLocationButtonTapped,
           .clearLocationButtonTapped,
           .setStatusBarOverrideButtonTapped,
           .clearStatusBarOverrideButtonTapped:
        return .none
      }
    }
  }
}
