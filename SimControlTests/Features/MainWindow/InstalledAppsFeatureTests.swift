import ComposableArchitecture
import Testing

@testable import SimControl

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
}
