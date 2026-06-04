import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlSharedUI
import SwiftUI

public struct DeveloperToolsView: View {
  let store: StoreOf<DeveloperToolsFeature>

  public init(store: StoreOf<DeveloperToolsFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      SectionHeader(title: "Developer Tools", systemImage: "wrench.and.screwdriver")

      LazyVGrid(
        columns: [
          GridItem(.adaptive(minimum: 280), spacing: 10)
        ],
        alignment: .leading,
        spacing: 10
      ) {
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

        PushPanel(
          bundleID: pushBundleID,
          payloadJSON: pushPayloadJSON,
          bundleIDOptions: store.appBundleIDOptions,
          selectedAppBundleID: store.selectedAppBundleID,
          disabledReason: store.sendPushDisabledReason,
          isRunning: isRunning(.pushNotification),
          onUseSelectedApp: {
            store.send(.useSelectedAppBundleButtonTapped)
          },
          onSend: {
            store.send(.sendPushButtonTapped)
          }
        )

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
