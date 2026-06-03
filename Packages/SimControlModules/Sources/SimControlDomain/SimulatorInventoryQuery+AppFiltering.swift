import Foundation

extension SimulatorInventoryQuery {
  func filteredApps(_ apps: [InstalledApp]) -> [InstalledApp] {
    apps.filter { app in
      appMatchesSystemFilter(app)
        && presence(app.appGroups.isEmpty, matches: filters.appGroupFilter)
        && presence(app.databaseFiles.isEmpty, matches: filters.appDatabaseFilter)
        && appMatchesSearch(app)
    }
  }

  func appMatchesSystemFilter(_ app: InstalledApp) -> Bool {
    switch filters.appSystemFilter {
    case .user:
      !app.isSystemApp
    case .system:
      app.isSystemApp
    case .all:
      true
    }
  }

  func presence(
    _ isEmpty: Bool,
    matches filter: SimulatorFilters.PresenceFilter
  ) -> Bool {
    switch filter {
    case .all:
      true
    case .present:
      !isEmpty
    case .absent:
      isEmpty
    }
  }

  func appMatchesSearch(_ app: InstalledApp) -> Bool {
    let query = filters.trimmedSearchQuery
    guard !query.isEmpty else {
      return true
    }

    return matches(query, in: appSearchCandidates(app))
  }

  func appSearchCandidates(_ app: InstalledApp) -> [String] {
    var candidates = [
      app.displayName,
      app.bundleID
    ]

    candidates.append(contentsOf: [
      app.bundleContainer?.path,
      app.dataContainer?.path,
      app.appBundlePath?.path
    ].compactMap { $0 })
    candidates.append(contentsOf: app.appGroups.flatMap { [$0.groupID, $0.path.path] })
    candidates.append(contentsOf: app.databaseFiles.map(\.path))

    return candidates
  }
}
