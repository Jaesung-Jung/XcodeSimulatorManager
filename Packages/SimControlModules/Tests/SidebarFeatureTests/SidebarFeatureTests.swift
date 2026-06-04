import ComposableArchitecture
import MainWindowFeatureSupport
import SidebarFeature
import Testing

@Suite("SidebarFeatureTests")
@MainActor
struct SidebarFeatureTests {
  @Test func stateCanBeConstructedAcrossModules() {
    let state = SidebarFeature.State(refreshState: .refreshing)

    #expect(state.snapshot == nil)
    #expect(state.refreshState == .refreshing)
  }

  @Test func reducerCanBeConstructedAcrossModules() async {
    let store = TestStore(initialState: SidebarFeature.State()) {
      SidebarFeature()
    }

    await store.finish()
  }
}
