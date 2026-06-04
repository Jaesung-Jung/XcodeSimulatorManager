@testable import MainWindowFeature
import Testing
import WorkspaceFeature

@Suite("MainWindowFeature")
struct MainWindowFeatureSmokeTests {
  @Test("initial state starts without an inventory snapshot")
  func initialStateStartsWithoutInventorySnapshot() {
    let state = MainWindowFeature.State()

    #expect(state.sidebar.snapshot == nil)
    #expect(state.workspace.snapshot == nil)
  }
}
