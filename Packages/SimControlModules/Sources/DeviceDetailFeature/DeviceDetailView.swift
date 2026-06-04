import ComposableArchitecture
import DeveloperToolsFeature
import InstalledAppsFeature
import SwiftUI

public struct DeviceDetailView: View {
  private let store: StoreOf<DeviceDetailFeature>

  public init(store: StoreOf<DeviceDetailFeature>) {
    self.store = store
  }

  private var appMetricValue: String {
    switch store.installedApps.availability {
    case .notLoaded:
      "Not loaded"
    case .loaded:
      "\(store.installedApps.apps.count)"
    }
  }

  public var body: some View {
    if let device = store.device {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Header(
            device: device,
            runtime: store.runtime,
            deviceType: store.deviceType,
            pairSummary: store.pairSummary,
            deviceCommandState: store.deviceCommandState,
            appCommandState: store.appCommandState,
            isOpeningSimulatorApp: store.isOpeningSimulatorApp,
            onBoot: {
              store.send(.bootButtonTapped(device.id))
            },
            onShutdown: {
              store.send(.shutdownButtonTapped(device.id))
            },
            onOpenSimulatorApp: {
              store.send(.openSimulatorAppButtonTapped)
            },
            onRename: {
              store.send(.renameButtonTapped(device.id))
            },
            onErase: {
              store.send(.eraseButtonTapped(device.id))
            },
            onDelete: {
              store.send(.deleteButtonTapped(device.id))
            },
            onUnpair: { pairID in
              store.send(.unpairButtonTapped(pairID))
            },
            onOpenDataFolder: {
              store.send(.openDeviceDataFolderButtonTapped(device.id))
            },
            onCopyDataPath: {
              store.send(.copyDeviceDataPathButtonTapped(device.id))
            },
            onOpenLogFolder: {
              store.send(.openDeviceLogFolderButtonTapped(device.id))
            },
            onCopyLogPath: {
              store.send(.copyDeviceLogPathButtonTapped(device.id))
            },
            onCopyUDID: {
              store.send(.copyDeviceUDIDButtonTapped(device.id))
            },
            onCopyRuntimeIdentifier: {
              store.send(.copyRuntimeIdentifierButtonTapped(device.id))
            },
            onCopyDeviceTypeIdentifier: {
              store.send(.copyDeviceTypeIdentifierButtonTapped(device.id))
            }
          )

          MetricsGrid(
            device: device,
            runtimeName: store.runtime?.name ?? device.runtimeID,
            appMetricValue: appMetricValue
          )

          InstalledAppsView(
            store: store.scope(state: \.installedApps, action: \.installedApps)
          )

          DeveloperToolsView(
            store: store.scope(state: \.developerTools, action: \.developerTools)
          )

          CommandResultsSection(results: store.commandResults)
        }
        .padding(20)
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
    }
  }
}

// MARK: - DeviceDetailView Preview

#if DEBUG

#Preview {
  DeviceDetailView(
    store: Store(initialState: DeviceDetailFeature.State()) {
      DeviceDetailFeature()
    }
  )
  .frame(width: 640, height: 720)
}

#endif
