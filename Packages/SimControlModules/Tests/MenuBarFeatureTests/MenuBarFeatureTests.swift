import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MenuBarFeature
import SimControlDomain
import Testing
import WorkspaceFeature

@Suite
@MainActor
struct MenuBarFeatureTests {
  @Test func rootViewCanBeConstructedWithoutMainWindowFeature() {
    let store = Store(initialState: MenuBarFeature.State()) {
      MenuBarFeature()
    }

    _ = MenuBarRootView(store: store)
  }

  @Test func stateProjectsWorkspaceValues() {
    var filters = SimulatorFilters()
    filters.pinnedDeviceIDs = ["DEVICE-1"]

    let snapshot = makeSnapshot()
    let workspace = WorkspaceFeature.State(
      snapshot: snapshot,
      refreshState: .refreshing,
      filters: filters
    )

    let state = MenuBarFeature.State(workspace: workspace)

    #expect(state.snapshot == snapshot)
    #expect(state.refreshState == .refreshing)
    #expect(state.filters == filters)
  }

  private func makeSnapshot() -> SimulatorSnapshot {
    SimulatorSnapshot(
      generatedAt: Date(timeIntervalSince1970: 1_000),
      xcode: XcodeSelection(
        developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
        version: nil,
        isValid: true
      ),
      runtimes: [],
      deviceTypes: [],
      devices: [],
      pairs: [],
      installedAppsByDeviceID: [:],
      warnings: []
    )
  }
}
