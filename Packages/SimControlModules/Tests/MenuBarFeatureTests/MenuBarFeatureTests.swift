import ComposableArchitecture
import MainWindowFeature
import MenuBarFeature
import Testing

@Suite
@MainActor
struct MenuBarFeatureTests {
  @Test func rootViewCanBeConstructedAcrossModules() {
    let store = Store(initialState: MainWindowFeature.State.initial) {
      MainWindowFeature()
    }

    _ = MenuBarRootView(store: store)
  }
}
