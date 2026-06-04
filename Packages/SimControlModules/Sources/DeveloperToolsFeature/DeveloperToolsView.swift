import ComposableArchitecture
import MainWindowFeatureSupport
import SwiftUI

public struct DeveloperToolsView: View {
  let store: StoreOf<DeveloperToolsFeature>

  public init(store: StoreOf<DeveloperToolsFeature>) {
    self.store = store
  }

  public var body: some View {
    LazyVStack(alignment: .leading, spacing: 16) {
      ToolSection(title: "Deep Link", systemImage: "link") {
        DeepLinkPanel(
          urlString: deepLinkURLString,
          recentURLs: store.recentDeepLinkURLs,
          disabledReason: store.openDeepLinkDisabledReason,
          isRunning: isRunning(.openURL),
          onRecentSelected: { urlString in
            store.send(.recentDeepLinkURLSelected(urlString))
          },
          onOpen: {
            store.send(.openDeepLinkButtonTapped)
          }
        )
      }

      ToolSection(title: "Remote Notification", systemImage: "bell.badge") {
        RemoteNotificationPanel(
          bundleID: remoteNotificationBundleID,
          payloadJSON: remoteNotificationPayloadJSON,
          bundleIDOptions: store.appBundleIDOptions,
          selectedAppBundleID: store.selectedAppBundleID,
          disabledReason: store.sendRemoteNotificationDisabledReason,
          isRunning: isRunning(.remoteNotification),
          onUseSelectedApp: {
            store.send(.useSelectedAppBundleButtonTapped)
          },
          onSend: {
            store.send(.sendRemoteNotificationButtonTapped)
          }
        )
      }

      ToolSection(title: "Privacy Permission", systemImage: "hand.raised") {
        PrivacyPanel(
          action: privacyAction,
          bundleID: privacyBundleID,
          service: store.privacyService,
          bundleIDOptions: store.appBundleIDOptions,
          selectedAppBundleID: store.selectedAppBundleID,
          disabledReason: store.applyPrivacyDisabledReason,
          isRunning: isRunning(.privacyPermission),
          onServiceSelected: { service in
            store.send(.privacyServiceChanged(service))
          },
          onUseSelectedApp: {
            store.send(.useSelectedAppBundleButtonTapped)
          },
          onApply: {
            store.send(.applyPrivacyButtonTapped)
          }
        )
      }

      ToolSection(title: "Location", systemImage: "location") {
        LocationPanel(
          preset: locationPreset,
          customLatitude: customLatitude,
          customLongitude: customLongitude,
          recentLocations: store.recentLocations,
          disabledReason: store.setLocationDisabledReason,
          clearDisabledReason: store.clearLocationDisabledReason,
          isSetRunning: isRunning(.setLocation),
          isClearRunning: isRunning(.clearLocation),
          onRecentSelected: { location in
            store.send(.recentLocationSelected(location))
          },
          onSet: {
            store.send(.setLocationButtonTapped)
          },
          onClear: {
            store.send(.clearLocationButtonTapped)
          }
        )
      }

      ToolSection(title: "Status Bar Override", systemImage: "rectangle.topthird.inset.filled") {
        StatusBarOverridePanel(
          time: statusBarTime,
          dataNetwork: statusBarDataNetwork,
          wifiMode: statusBarWifiMode,
          wifiBars: statusBarWifiBars,
          cellularMode: statusBarCellularMode,
          cellularBars: statusBarCellularBars,
          operatorNameIncluded: statusBarOperatorNameIncluded,
          operatorName: statusBarOperatorName,
          batteryState: statusBarBatteryState,
          batteryLevel: statusBarBatteryLevel,
          disabledReason: store.setStatusBarOverrideDisabledReason,
          clearDisabledReason: store.clearStatusBarOverrideDisabledReason,
          isApplyRunning: isRunning(.statusBarOverride),
          isClearRunning: isRunning(.clearStatusBarOverride),
          onApply: {
            store.send(.setStatusBarOverrideButtonTapped)
          },
          onClear: {
            store.send(.clearStatusBarOverrideButtonTapped)
          }
        )
      }
    }
  }

  private func isRunning(_ command: DeviceCommand) -> Bool {
    store.deviceCommandState?.command == command
  }
}

// MARK: - DeveloperToolsView Preview

#if DEBUG

#Preview {
  DeveloperToolsView(
    store: Store(
      initialState: DeveloperToolsFeature.State()
    ) {
      DeveloperToolsFeature()
    }
  )
  .padding(20)
  .frame(width: 720)
}

#endif
