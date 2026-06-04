import ComposableArchitecture
import SimControlDomain
import SwiftUI

/// Renders simulator inventory filters in the sidebar.
public struct Sidebar: View {
  private let store: StoreOf<SidebarFeature>
  private let filters: SimulatorFilters
  private let onScopeSelected: (SimulatorFilters.SidebarScope) -> Void

  /// Creates a sidebar bound to sidebar state and an external filter selection handler.
  public init(
    store: StoreOf<SidebarFeature>,
    filters: SimulatorFilters,
    onScopeSelected: @escaping (SimulatorFilters.SidebarScope) -> Void
  ) {
    self.store = store
    self.filters = filters
    self.onScopeSelected = onScopeSelected
  }

  public var body: some View {
    Content(
      snapshot: store.snapshot,
      refreshState: store.refreshState,
      filters: filters,
      onScopeSelected: onScopeSelected
    )
  }
}

// MARK: - Sidebar Preview

#if DEBUG

#Preview {
  Sidebar(
    store: Store(initialState: SidebarFeature.State()) {
      SidebarFeature()
    },
    filters: SimulatorFilters(),
    onScopeSelected: { _ in }
  )
  .frame(width: 240, height: 720)
}

#endif
