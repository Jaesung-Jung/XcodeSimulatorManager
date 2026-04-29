import ComposableArchitecture
import Testing

@testable import SimControl

@MainActor
struct WorkspaceFeatureTests {
  @Test
  func selectingDifferentDeviceClearsSelectedAppAndUpdatesInspector() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    let initialState = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: MainWindowTestFixtures.app.id,
      installedAppsAvailability: .loaded
    )

    let store = TestStore(initialState: initialState) {
      WorkspaceFeature()
    }

    await store.send(.deviceList(.selectionChanged(MainWindowTestFixtures.secondDevice.id))) {
      $0.deviceList.selectedDeviceID = MainWindowTestFixtures.secondDevice.id
      $0.deviceDetail = DeviceDetailFeature.State(
        device: MainWindowTestFixtures.secondDevice,
        runtime: MainWindowTestFixtures.runtime,
        deviceType: MainWindowTestFixtures.deviceType,
        installedApps: InstalledAppsFeature.State(
          apps: [MainWindowTestFixtures.secondApp],
          availability: .loaded
        )
      )
      $0.inspector = InspectorFeature.State(
        snapshot: snapshot,
        device: MainWindowTestFixtures.secondDevice,
        runtime: MainWindowTestFixtures.runtime,
        deviceType: MainWindowTestFixtures.deviceType
      )
    }
  }

  @Test
  func selectingAppUpdatesDetailAndInspector() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app]
      ]
    )
    let initialState = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      installedAppsAvailability: .loaded
    )

    let store = TestStore(initialState: initialState) {
      WorkspaceFeature()
    }

    await store.send(.deviceDetail(.installedApps(.selectionChanged(MainWindowTestFixtures.app.id)))) {
      $0.deviceDetail.installedApps.selectedAppID = MainWindowTestFixtures.app.id
      $0.inspector.selectedApp = MainWindowTestFixtures.app
    }
  }
}
