import ComposableArchitecture
import SimControlDomain
import SwiftUI

extension InstalledAppsView {
  var appSystemFilter: Binding<SimulatorFilters.AppSystemFilter> {
    Binding(
      get: { store.filters.appSystemFilter },
      set: { store.send(.appSystemFilterChanged($0)) }
    )
  }

  var appGroupFilter: Binding<SimulatorFilters.PresenceFilter> {
    Binding(
      get: { store.filters.appGroupFilter },
      set: { store.send(.appGroupFilterChanged($0)) }
    )
  }

  var showsHiddenSystemApps: Binding<Bool> {
    Binding(
      get: { store.filters.showsHiddenSystemApps },
      set: { store.send(.showHiddenSystemAppsChanged($0)) }
    )
  }

  var appDatabaseFilter: Binding<SimulatorFilters.PresenceFilter> {
    Binding(
      get: { store.filters.appDatabaseFilter },
      set: { store.send(.appDatabaseFilterChanged($0)) }
    )
  }

  var appSort: Binding<SimulatorFilters.AppSort> {
    Binding(
      get: { store.filters.appSort },
      set: { store.send(.appSortChanged($0)) }
    )
  }

  var appSortDirection: Binding<SimulatorFilters.SortDirection> {
    Binding(
      get: { store.filters.appSortDirection },
      set: { store.send(.appSortDirectionChanged($0)) }
    )
  }
}
