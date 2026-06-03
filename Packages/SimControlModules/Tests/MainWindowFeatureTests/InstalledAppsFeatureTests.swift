import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import SimControlDomain
import Testing

@testable import MainWindowFeature

@MainActor
struct InstalledAppsFeatureTests {
  @Test
  func selectingAppStoresSelectedAppID() async {
    let store = TestStore(
      initialState: InstalledAppsFeature.State(
        apps: [MainWindowTestFixtures.app],
        availability: .loaded
      )
    ) {
      InstalledAppsFeature()
    }

    await store.send(.selectionChanged(MainWindowTestFixtures.app.id)) {
      $0.selectedAppID = MainWindowTestFixtures.app.id
    }
  }

  @Test
  func nilSelectionClearsSelectedAppID() async {
    let store = TestStore(
      initialState: InstalledAppsFeature.State(
        apps: [MainWindowTestFixtures.app],
        availability: .loaded,
        selectedAppID: MainWindowTestFixtures.app.id
      )
    ) {
      InstalledAppsFeature()
    }

    await store.send(.selectionChanged(nil)) {
      $0.selectedAppID = nil
    }
  }

  @Test
  func loadedAvailabilityClearsStaleSelectedApp() {
    let state = InstalledAppsFeature.State(
      apps: [],
      availability: .loaded,
      selectedAppID: MainWindowTestFixtures.app.id
    )

    #expect(state.selectedAppID == nil)
  }

  @Test
  func notLoadedAvailabilityPreservesStaleSelectedAppID() {
    let state = InstalledAppsFeature.State(
      apps: [],
      availability: .notLoaded,
      selectedAppID: MainWindowTestFixtures.app.id
    )

    #expect(state.selectedAppID == MainWindowTestFixtures.app.id)
  }

  @Test
  func selectedAppActionAvailabilityFollowsDeviceStateAndPaths() {
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: MainWindowTestFixtures.device.id,
      bundleID: "com.example.app",
      dataContainer: URL(fileURLWithPath: "/tmp/Data"),
      appBundlePath: URL(fileURLWithPath: "/tmp/Example.app")
    )
    let state = InstalledAppsFeature.State(
      apps: [app],
      availability: .loaded,
      device: MainWindowTestFixtures.makeDevice(
        id: MainWindowTestFixtures.device.id,
        state: .booted
      ),
      selectedAppID: app.id,
      compatibleInstallTargetCount: 1
    )

    #expect(state.canLaunchSelectedApp)
    #expect(state.canTerminateSelectedApp)
    #expect(state.canUninstallSelectedApp)
    #expect(state.canResetSelectedAppSandbox)
    #expect(state.canInstallSelectedAppOnAnotherSimulator)
  }

  @Test
  func runningCommandDisablesSelectedAppActions() {
    let appCommandState = AppCommandState(
      command: .launch,
      sourceDeviceID: MainWindowTestFixtures.device.id,
      appID: MainWindowTestFixtures.app.id
    )
    let state = InstalledAppsFeature.State(
      apps: [MainWindowTestFixtures.app],
      availability: .loaded,
      device: MainWindowTestFixtures.device,
      selectedAppID: MainWindowTestFixtures.app.id,
      appCommandState: appCommandState,
      compatibleInstallTargetCount: 1
    )

    #expect(!state.canLaunchSelectedApp)
    #expect(!state.canTerminateSelectedApp)
    #expect(!state.canUninstallSelectedApp)
    #expect(!state.canResetSelectedAppSandbox)
    #expect(!state.canInstallSelectedAppOnAnotherSimulator)
  }
}
