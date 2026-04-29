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

  @Test
  func applySnapshotUsesPreferredSelectedDeviceAndClearsSelectedApp() {
    let oldSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    let newSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app],
        MainWindowTestFixtures.secondDevice.id: [MainWindowTestFixtures.secondApp]
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: oldSnapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: MainWindowTestFixtures.app.id,
      installedAppsAvailability: .loaded
    )

    state.applySnapshot(
      newSnapshot,
      refreshState: .idle,
      commandResults: [],
      preferredSelectedDeviceID: MainWindowTestFixtures.secondDevice.id
    )

    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.secondDevice.id)
    #expect(state.deviceDetail.device == MainWindowTestFixtures.secondDevice)
    #expect(state.deviceDetail.installedApps.selectedAppID == nil)
    #expect(state.inspector.device == MainWindowTestFixtures.secondDevice)
  }

  @Test
  func applySnapshotFallsBackWhenPreferredSelectedDeviceIsMissing() {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ]
    )
    var state = WorkspaceFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id
    )

    state.applySnapshot(
      snapshot,
      refreshState: .idle,
      commandResults: [],
      preferredSelectedDeviceID: "MISSING"
    )

    #expect(state.deviceList.selectedDeviceID == MainWindowTestFixtures.device.id)
    #expect(state.deviceDetail.device == MainWindowTestFixtures.device)
    #expect(state.inspector.device == MainWindowTestFixtures.device)
  }
}
