import ComposableArchitecture
import SwiftUI

@MainActor
struct MainWindowView: View {
  let store: StoreOf<MainWindowFeature>

  private var isRefreshing: Bool {
    store.workspace.refreshState == .refreshing
  }

  var body: some View {
    NavigationSplitView {
      Sidebar(
        store: store.scope(state: \.sidebar, action: \.sidebar)
      )
      .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
    } content: {
      DeviceListView(
        store: store.scope(
          state: \.workspace.deviceList,
          action: \.workspace.deviceList
        )
      )
      .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 420)
    } detail: {
      WorkspaceView(
        store: store.scope(state: \.workspace, action: \.workspace)
      )
      .frame(minWidth: 580)
    }
    .frame(minWidth: 1_120, minHeight: 720)
    .background(.windowBackground)
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button {
          store.send(.refreshButtonTapped)
        } label: {
          if isRefreshing {
            ProgressView()
              .controlSize(.small)
              .frame(width: 18, height: 18)
          } else {
            Label("Refresh", systemImage: "arrow.clockwise")
          }
        }
        .disabled(isRefreshing)
        .help("Refresh simulator inventory")
        .keyboardShortcut("r", modifiers: .command)
      }
    }
    .task {
      await store.send(.task).finish()
    }
  }
}

// MARK: - MainWindowView Preview

#if DEBUG

#Preview {
  MainWindowView(store: .mainWindowPreview)
}

#endif
