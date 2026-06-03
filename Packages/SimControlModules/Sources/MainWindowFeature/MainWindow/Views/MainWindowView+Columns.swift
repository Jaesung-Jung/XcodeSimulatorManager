import ComposableArchitecture
import DeviceListFeature
import InspectorFeature
import SidebarFeature
import SwiftUI
import WorkspaceFeature

// MARK: - MainWindowView Columns

@MainActor
extension MainWindowView {
  struct SidebarColumn: View {
    let store: StoreOf<MainWindowFeature>

    var body: some View {
      Sidebar(
        store: store.scope(state: \.sidebar, action: \.sidebar),
        filters: store.workspace.filters,
        onScopeSelected: { scope in
          store.send(.workspace(.sidebarScopeChanged(scope)))
        }
      )
      .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
    }
  }

  struct DeviceListColumn: View {
    let store: StoreOf<MainWindowFeature>

    var body: some View {
      DeviceListView(
        store: store.scope(
          state: \.workspace.deviceList,
          action: \.workspace.deviceList
        )
      )
      .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 420)
    }
  }

  struct WorkspaceDetail: View {
    let store: StoreOf<MainWindowFeature>

    var body: some View {
      WorkspaceView(
        store: store.scope(state: \.workspace, action: \.workspace)
      )
    }
  }

  struct InspectorPane: View {
    let store: StoreOf<MainWindowFeature>

    var body: some View {
      InspectorView(
        store: store.scope(
          state: \.workspace.inspector,
          action: \.workspace.inspector
        )
      )
      .background(.windowBackground)
    }
  }
}
