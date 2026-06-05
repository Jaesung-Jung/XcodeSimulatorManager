import ComposableArchitecture
import DeveloperToolsFeature
import Foundation
import InstalledAppsFeature
import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

/// Renders details and actions for the selected simulator device.
public struct DeviceDetailView: View {
  private let store: StoreOf<DeviceDetailFeature>

  /// Creates a device detail view bound to a device detail store.
  public init(store: StoreOf<DeviceDetailFeature>) {
    self.store = store
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
            runtimeName: store.runtime?.name ?? device.runtimeID
          )

          InstalledAppsView(
            store: store.scope(state: \.installedApps, action: \.installedApps)
          )

          DeveloperToolsView(
            store: store.scope(state: \.developerTools, action: \.developerTools)
          )
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
  let runtime = SimulatorRuntime(
    id: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: ["com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"]
  )
  let deviceType = SimulatorDeviceType(
    id: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    name: "iPhone 17 Pro",
    productFamily: "iPhone",
    modelIdentifier: "iPhone18,1"
  )
  let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "9A83C4C2-B8D2-4F51-9244-0C8A8E3F7C11",
    name: "iPhone 17 Pro",
    runtimeID: runtime.id,
    deviceTypeID: deviceType.id,
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: URL(fileURLWithPath: "/Users/preview/Library/Developer/CoreSimulator/Devices/PREVIEW-DEVICE-1/data"),
    logPath: URL(fileURLWithPath: "/Users/preview/Library/Logs/CoreSimulator/PREVIEW-DEVICE-1"),
    lastBootedAt: Date(timeIntervalSince1970: 1_778_008_400),
    dataPathSize: 5_243_912_704
  )
  let readingApp = InstalledApp(
    id: "PREVIEW-DEVICE-1-com.example.reading",
    bundleID: "com.example.reading",
    displayName: "Reading Notes",
    version: "2.4.1",
    build: "184",
    deviceID: device.id,
    bundleContainer: URL(fileURLWithPath: "/Users/preview/Containers/Bundle/Application/ReadingNotes"),
    dataContainer: URL(fileURLWithPath: "/Users/preview/Containers/Data/Application/ReadingNotes"),
    appBundlePath: URL(fileURLWithPath: "/Users/preview/Containers/Bundle/Application/ReadingNotes/Reading Notes.app"),
    appGroups: [
      AppGroupContainer(
        id: "PREVIEW-GROUP-READING",
        groupID: "group.com.example.reading.shared",
        path: URL(fileURLWithPath: "/Users/preview/Containers/Shared/AppGroup/ReadingNotes")
      )
    ],
    iconPath: nil,
    databaseFiles: [
      URL(fileURLWithPath: "/Users/preview/Containers/Data/Application/ReadingNotes/Documents/notes.sqlite")
    ],
    dataContainerSize: 184_320_000
  )
  let settingsApp = InstalledApp(
    id: "PREVIEW-DEVICE-1-com.example.settings",
    bundleID: "com.example.settings",
    displayName: "Settings Lab",
    version: "1.0",
    build: "42",
    deviceID: device.id,
    bundleContainer: URL(fileURLWithPath: "/Users/preview/Containers/Bundle/Application/SettingsLab"),
    dataContainer: URL(fileURLWithPath: "/Users/preview/Containers/Data/Application/SettingsLab"),
    appBundlePath: URL(fileURLWithPath: "/Users/preview/Containers/Bundle/Application/SettingsLab/Settings Lab.app"),
    appGroups: [],
    iconPath: nil,
    databaseFiles: [],
    dataContainerSize: 42_800_000
  )
  DeviceDetailView(
    store: Store(
      initialState: DeviceDetailFeature.State(
        device: device,
        runtime: runtime,
        deviceType: deviceType,
        installedApps: InstalledAppsFeature.State(
          apps: [readingApp, settingsApp],
          availability: .loaded,
          device: device,
          selectedAppID: readingApp.id,
          compatibleInstallTargetCount: 2
        )
      )
    ) {
      DeviceDetailFeature()
    }
  )
  .frame(width: 640, height: 720)
}

#endif
