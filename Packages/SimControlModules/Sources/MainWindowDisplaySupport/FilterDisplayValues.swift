import SimControlDomain

extension SimulatorFilters.SidebarScope {
  public var displayTitle: String {
    switch self {
    case .all:
      "All Devices"
    case .pinned:
      "Bookmark"
    case .warnings:
      "Warnings"
    case .platform(let platform):
      platform.displayTitle
    case .runtime(let runtimeID):
      runtimeID
    case .state(let state):
      state.displayTitle
    }
  }
}

extension SimulatorFilters.SortDirection {
  public var displayTitle: String {
    switch self {
    case .ascending:
      "Ascending"
    case .descending:
      "Descending"
    }
  }
}

extension SimulatorFilters.DeviceSort {
  public var displayTitle: String {
    switch self {
    case .name:
      "Name"
    case .state:
      "State"
    case .runtime:
      "Runtime"
    case .platform:
      "Platform"
    case .lastBootedAt:
      "Last Booted"
    case .dataSize:
      "Data Size"
    }
  }
}

extension SimulatorFilters.AppSort {
  public var displayTitle: String {
    switch self {
    case .name:
      "Name"
    case .bundleID:
      "Bundle ID"
    case .version:
      "Version"
    case .dataSize:
      "Data Size"
    }
  }
}

extension SimulatorFilters.AppSystemFilter {
  public var displayTitle: String {
    switch self {
    case .user:
      "User Apps"
    case .system:
      "System Apps"
    case .all:
      "All Apps"
    }
  }
}

extension SimulatorFilters.PresenceFilter {
  public var appGroupDisplayTitle: String {
    switch self {
    case .all:
      "Any App Groups"
    case .present:
      "Has App Groups"
    case .absent:
      "No App Groups"
    }
  }

  public var databaseDisplayTitle: String {
    switch self {
    case .all:
      "Any Databases"
    case .present:
      "Has Databases"
    case .absent:
      "No Databases"
    }
  }
}
