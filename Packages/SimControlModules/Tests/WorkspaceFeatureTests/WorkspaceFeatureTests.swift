import ComposableArchitecture
import MainWindowFeatureSupport
import Testing
import WorkspaceFeature

@Suite
@MainActor
struct WorkspaceFeatureTests {
  @Test func stateCanBeConstructedAcrossModules() {
    let state = WorkspaceFeature.State(refreshState: .refreshing)

    #expect(state.snapshot == nil)
    #expect(state.refreshState == .refreshing)
    #expect(state.installedAppsAvailability == .notLoaded)
  }

  @Test func reducerCanBeConstructedAcrossModules() async {
    let store = TestStore(initialState: WorkspaceFeature.State()) {
      WorkspaceFeature()
    }

    await store.send(.searchQueryChanged("iphone")) {
      $0.filters.searchQuery = "iphone"
      $0.deviceList.filters.searchQuery = "iphone"
      $0.deviceDetail.installedApps.filters.searchQuery = "iphone"
    }
  }
}
