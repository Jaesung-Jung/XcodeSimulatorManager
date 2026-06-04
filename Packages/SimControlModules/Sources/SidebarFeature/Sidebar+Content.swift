import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

// MARK: - Sidebar.Content

extension Sidebar {
  struct Content: View {
    let snapshot: SimulatorSnapshot?
    let refreshState: InventoryRefreshState
    let filters: SimulatorFilters
    let onScopeSelected: (SimulatorFilters.SidebarScope) -> Void

    private var sidebarScopeSelection: Binding<SimulatorFilters.SidebarScope?> {
      Binding(
        get: { filters.sidebarScope },
        set: { scope in
          guard let scope else {
            return
          }

          onScopeSelected(scope)
        }
      )
    }

    var body: some View {
      List(selection: sidebarScopeSelection) {
        InventorySection(
          snapshot: snapshot,
          filters: filters
        )

        PlatformsSection(platformCounts: snapshot?.platformCounts ?? [])

        RuntimesSection(runtimeCounts: snapshot?.runtimeCounts ?? [])

        DeviceStateSection(stateCounts: snapshot?.stateCounts ?? [])

        EnvironmentSection(
          snapshot: snapshot,
          refreshState: refreshState
        )
      }
      .listStyle(.sidebar)
      .navigationTitle("SimControl")
    }
  }
}

// MARK: - Sidebar.Content Preview

#if DEBUG

#Preview {
  Sidebar.Content(
    snapshot: nil,
    refreshState: .idle,
    filters: SimulatorFilters(),
    onScopeSelected: { _ in }
  )
  .frame(width: 240, height: 520)
}

#endif
