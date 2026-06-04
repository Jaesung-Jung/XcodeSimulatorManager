import ComposableArchitecture
import SwiftUI

extension DeveloperToolsView {
  var deepLinkURLString: Binding<String> {
    Binding(
      get: { store.deepLinkURLString },
      set: { store.send(.deepLinkURLChanged($0)) }
    )
  }

  var remoteNotificationBundleID: Binding<String> {
    Binding(
      get: { store.remoteNotificationBundleID },
      set: { store.send(.remoteNotificationBundleIDChanged($0)) }
    )
  }

  var remoteNotificationPayloadJSON: Binding<String> {
    Binding(
      get: { store.remoteNotificationPayloadJSON },
      set: { store.send(.remoteNotificationPayloadJSONChanged($0)) }
    )
  }

  var privacyAction: Binding<DeveloperToolsFeature.PrivacyAction> {
    Binding(
      get: { store.privacyAction },
      set: { store.send(.privacyActionChanged($0)) }
    )
  }

  var privacyBundleID: Binding<String> {
    Binding(
      get: { store.privacyBundleID },
      set: { store.send(.privacyBundleIDChanged($0)) }
    )
  }

  var locationPreset: Binding<DeveloperToolsFeature.LocationPreset> {
    Binding(
      get: { store.locationPreset },
      set: { store.send(.locationPresetChanged($0)) }
    )
  }

  var customLatitude: Binding<String> {
    Binding(
      get: { store.customLatitude },
      set: { store.send(.customLatitudeChanged($0)) }
    )
  }

  var customLongitude: Binding<String> {
    Binding(
      get: { store.customLongitude },
      set: { store.send(.customLongitudeChanged($0)) }
    )
  }

  var statusBarTime: Binding<String> {
    Binding(
      get: { store.statusBarTime },
      set: { store.send(.statusBarTimeChanged($0)) }
    )
  }

  var statusBarDataNetwork: Binding<DeveloperToolsFeature.StatusBarDataNetwork?> {
    Binding(
      get: { store.statusBarDataNetwork },
      set: { store.send(.statusBarDataNetworkChanged($0)) }
    )
  }

  var statusBarWifiMode: Binding<DeveloperToolsFeature.StatusBarWifiMode?> {
    Binding(
      get: { store.statusBarWifiMode },
      set: { store.send(.statusBarWifiModeChanged($0)) }
    )
  }

  var statusBarWifiBars: Binding<String> {
    Binding(
      get: { store.statusBarWifiBars },
      set: { store.send(.statusBarWifiBarsChanged($0)) }
    )
  }

  var statusBarCellularMode: Binding<DeveloperToolsFeature.StatusBarCellularMode?> {
    Binding(
      get: { store.statusBarCellularMode },
      set: { store.send(.statusBarCellularModeChanged($0)) }
    )
  }

  var statusBarCellularBars: Binding<String> {
    Binding(
      get: { store.statusBarCellularBars },
      set: { store.send(.statusBarCellularBarsChanged($0)) }
    )
  }

  var statusBarOperatorNameIncluded: Binding<Bool> {
    Binding(
      get: { store.statusBarOperatorNameIncluded },
      set: { store.send(.statusBarOperatorNameIncludedChanged($0)) }
    )
  }

  var statusBarOperatorName: Binding<String> {
    Binding(
      get: { store.statusBarOperatorName },
      set: { store.send(.statusBarOperatorNameChanged($0)) }
    )
  }

  var statusBarBatteryState: Binding<DeveloperToolsFeature.StatusBarBatteryState?> {
    Binding(
      get: { store.statusBarBatteryState },
      set: { store.send(.statusBarBatteryStateChanged($0)) }
    )
  }

  var statusBarBatteryLevel: Binding<String> {
    Binding(
      get: { store.statusBarBatteryLevel },
      set: { store.send(.statusBarBatteryLevelChanged($0)) }
    )
  }
}
