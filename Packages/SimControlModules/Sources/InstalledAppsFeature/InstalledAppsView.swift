import ComposableArchitecture
import SwiftUI

public struct InstalledAppsView: View {
  let store: StoreOf<InstalledAppsFeature>

  public init(store: StoreOf<InstalledAppsFeature>) {
    self.store = store
  }

  public var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      InstalledAppsHeader(
        isLoaded: store.availability == .loaded,
        systemFilter: appSystemFilter,
        appGroupFilter: appGroupFilter,
        databaseFilter: appDatabaseFilter,
        sort: appSort,
        direction: appSortDirection
      )

      if store.filters.hasActiveAppFilters {
        ActiveAppFilters(
          filters: store.filters,
          onClear: {
            store.send(.clearAppFiltersButtonTapped)
          }
        )
      }

      InstalledAppsContent(store: store)
    }
  }
}

// MARK: - InstalledAppsView Preview

#if DEBUG

#Preview {
  InstalledAppsView(
    store: Store(
      initialState: InstalledAppsFeature.State(availability: .loaded)
    ) {
      InstalledAppsFeature()
    }
  )
  .padding(20)
}

#endif
