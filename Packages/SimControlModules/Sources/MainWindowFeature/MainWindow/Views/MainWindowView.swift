import ComposableArchitecture
import SimControlDomain
import SwiftUI

@MainActor
public struct MainWindowView: View {
  @State private var isInspectorPresented = true

  let store: StoreOf<MainWindowFeature>

  public init(store: StoreOf<MainWindowFeature>) {
    self.store = store
  }

  private var isRefreshing: Bool {
    store.workspace.refreshState == .refreshing
  }

  private var lifecycleSheet: Binding<MainWindowFeature.DeviceLifecycleSheet?> {
    Binding(
      get: { store.lifecycleSheet },
      set: { sheet in
        if sheet == nil {
          store.send(.lifecycleSheetDismissed)
        }
      }
    )
  }

  private var searchQuery: Binding<String> {
    Binding(
      get: { store.workspace.filters.searchQuery },
      set: { store.send(.workspace(.searchQueryChanged($0))) }
    )
  }

  public var body: some View {
    NavigationSplitView {
      SidebarColumn(store: store)
    } content: {
      DeviceListColumn(store: store)
    } detail: {
      WorkspaceDetail(store: store)
    }
    .inspector(isPresented: $isInspectorPresented) {
      InspectorPane(store: store)
    }
    .frame(minWidth: 1_120, minHeight: 720)
    .background(.windowBackground)
    .toolbar {
      MainToolbar(
        store: store,
        isRefreshing: isRefreshing,
        isInspectorPresented: $isInspectorPresented
      )
    }
    .sheet(item: lifecycleSheet) { sheet in
      LifecycleSheetContent(store: store, sheet: sheet)
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
