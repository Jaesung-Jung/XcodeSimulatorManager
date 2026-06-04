import ComposableArchitecture
import Foundation
import InstalledAppsFeature
import MainWindowFeatureSupport
import SimControlDomain
import Testing

@Suite
@MainActor
struct InstalledAppsFeatureTests {
  @Test func stateCanBeConstructedAcrossModules() {
    let app = InstalledApp(
      id: "app-1",
      bundleID: "com.example.app",
      displayName: "Example",
      version: nil,
      build: nil,
      deviceID: "device-1",
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil
    )

    let state = InstalledAppsFeature.State(
      apps: [app],
      availability: .loaded,
      selectedAppID: app.id,
      allAppsCount: 1
    )

    #expect(state.apps.map(\.id) == [app.id])
    #expect(state.availability == .loaded)
    #expect(state.selectedAppID == app.id)
    #expect(state.selectedApp?.id == app.id)
  }

  @Test func selectionChangedStoresSelectedAppID() async {
    let store = TestStore(initialState: InstalledAppsFeature.State()) {
      InstalledAppsFeature()
    }

    await store.send(.selectionChanged("app-1")) {
      $0.selectedAppID = "app-1"
    }
  }
}
