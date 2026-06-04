import SimControlDomain
import SimControlSharedUI
import SwiftUI

extension InstalledAppsView {
  struct InstalledAppsHeader: View {
    let isLoaded: Bool
    let visibleAppCount: Int
    let allAppsCount: Int
    @Binding var systemFilter: SimulatorFilters.AppSystemFilter
    @Binding var appGroupFilter: SimulatorFilters.PresenceFilter
    @Binding var databaseFilter: SimulatorFilters.PresenceFilter
    @Binding var sort: SimulatorFilters.AppSort
    @Binding var direction: SimulatorFilters.SortDirection

    var body: some View {
      HStack(spacing: 8) {
        SectionHeader(title: "Installed Apps", systemImage: "app")

        Spacer()

        if isLoaded {
          Text("\(visibleAppCount) of \(allAppsCount)")
            .font(.caption)
            .foregroundStyle(.secondary)

          AppFilterMenu(
            systemFilter: $systemFilter,
            appGroupFilter: $appGroupFilter,
            databaseFilter: $databaseFilter
          )

          AppSortMenu(
            sort: $sort,
            direction: $direction
          )
        }
      }
    }
  }
}

// MARK: - InstalledAppsView.InstalledAppsHeader Preview

#if DEBUG

#Preview {
  VStack(alignment: .leading, spacing: 12) {
    InstalledAppsView.InstalledAppsHeader(
      isLoaded: true,
      visibleAppCount: 2,
      allAppsCount: 5,
      systemFilter: .constant(.user),
      appGroupFilter: .constant(.all),
      databaseFilter: .constant(.present),
      sort: .constant(.name),
      direction: .constant(.ascending)
    )

    InstalledAppsView.ActiveAppFilters(
      filters: SimulatorFilters(appDatabaseFilter: .present),
      onClear: {}
    )
  }
  .padding(20)
  .frame(width: 460)
}

#endif

extension InstalledAppsView {
  struct AppFilterMenu: View {
    @Binding var systemFilter: SimulatorFilters.AppSystemFilter
    @Binding var appGroupFilter: SimulatorFilters.PresenceFilter
    @Binding var databaseFilter: SimulatorFilters.PresenceFilter

    var body: some View {
      Menu {
        Picker("App Type", selection: $systemFilter) {
          Text(SimulatorFilters.AppSystemFilter.user.displayTitle)
            .tag(SimulatorFilters.AppSystemFilter.user)
          Text(SimulatorFilters.AppSystemFilter.system.displayTitle)
            .tag(SimulatorFilters.AppSystemFilter.system)
          Text(SimulatorFilters.AppSystemFilter.all.displayTitle)
            .tag(SimulatorFilters.AppSystemFilter.all)
        }

        Picker("App Groups", selection: $appGroupFilter) {
          Text(SimulatorFilters.PresenceFilter.all.appGroupDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.all)
          Text(SimulatorFilters.PresenceFilter.present.appGroupDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.present)
          Text(SimulatorFilters.PresenceFilter.absent.appGroupDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.absent)
        }

        Picker("Databases", selection: $databaseFilter) {
          Text(SimulatorFilters.PresenceFilter.all.databaseDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.all)
          Text(SimulatorFilters.PresenceFilter.present.databaseDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.present)
          Text(SimulatorFilters.PresenceFilter.absent.databaseDisplayTitle)
            .tag(SimulatorFilters.PresenceFilter.absent)
        }
      } label: {
        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
      }
      .help("Filter installed apps")
    }
  }
}

extension InstalledAppsView {
  struct AppSortMenu: View {
    @Binding var sort: SimulatorFilters.AppSort
    @Binding var direction: SimulatorFilters.SortDirection

    var body: some View {
      Menu {
        Picker("Sort By", selection: $sort) {
          Text(SimulatorFilters.AppSort.name.displayTitle)
            .tag(SimulatorFilters.AppSort.name)
          Text(SimulatorFilters.AppSort.bundleID.displayTitle)
            .tag(SimulatorFilters.AppSort.bundleID)
          Text(SimulatorFilters.AppSort.version.displayTitle)
            .tag(SimulatorFilters.AppSort.version)
          Text(SimulatorFilters.AppSort.dataSize.displayTitle)
            .tag(SimulatorFilters.AppSort.dataSize)
        }

        Divider()

        Picker("Direction", selection: $direction) {
          Text(SimulatorFilters.SortDirection.ascending.displayTitle)
            .tag(SimulatorFilters.SortDirection.ascending)
          Text(SimulatorFilters.SortDirection.descending.displayTitle)
            .tag(SimulatorFilters.SortDirection.descending)
        }
      } label: {
        Label("Sort", systemImage: "arrow.up.arrow.down")
      }
      .help("Sort installed apps")
    }
  }
}

extension InstalledAppsView {
  struct ActiveAppFilters: View {
    let filters: SimulatorFilters
    let onClear: () -> Void

    var body: some View {
      HStack(spacing: 6) {
        if filters.appSystemFilter != .user {
          FilterChip(title: filters.appSystemFilter.displayTitle)
        }

        if filters.appGroupFilter != .all {
          FilterChip(title: filters.appGroupFilter.appGroupDisplayTitle)
        }

        if filters.appDatabaseFilter != .all {
          FilterChip(title: filters.appDatabaseFilter.databaseDisplayTitle)
        }

        Spacer(minLength: 4)

        Button("Clear") {
          onClear()
        }
        .buttonStyle(.plain)
        .font(.caption)
      }
    }
  }
}

extension InstalledAppsView {
  struct FilterChip: View {
    let title: String

    var body: some View {
      Text(title)
        .font(.caption)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.45), in: Capsule())
    }
  }
}
