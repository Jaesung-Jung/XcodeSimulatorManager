import SimControlDomain

// MARK: - WorkspaceFeature.State Filters

extension WorkspaceFeature.State {
  public mutating func setSearchQuery(_ query: String) {
    filters.searchQuery = query
    let searchTarget = inventoryQuery?.exactSearchTarget()
    rebuildAfterFilterChange(
      preferredSelectedDeviceID: searchTarget?.deviceID,
      preferredSelectedAppID: searchTarget?.appID
    )
  }

  public mutating func setSidebarScope(_ scope: SimulatorFilters.SidebarScope) {
    filters.sidebarScope = scope
    rebuildAfterFilterChange()
  }

  public mutating func setDeviceSort(_ sort: SimulatorFilters.DeviceSort) {
    filters.deviceSort = sort
    rebuildAfterFilterChange()
  }

  public mutating func setDeviceSortDirection(_ direction: SimulatorFilters.SortDirection) {
    filters.deviceSortDirection = direction
    rebuildAfterFilterChange()
  }

  public mutating func setAppSystemFilter(_ filter: SimulatorFilters.AppSystemFilter) {
    filters.appSystemFilter = filter
    rebuildAfterFilterChange()
  }

  public mutating func setAppGroupFilter(_ filter: SimulatorFilters.PresenceFilter) {
    filters.appGroupFilter = filter
    rebuildAfterFilterChange()
  }

  public mutating func setAppDatabaseFilter(_ filter: SimulatorFilters.PresenceFilter) {
    filters.appDatabaseFilter = filter
    rebuildAfterFilterChange()
  }

  public mutating func setAppSort(_ sort: SimulatorFilters.AppSort) {
    filters.appSort = sort
    rebuildAfterFilterChange()
  }

  public mutating func setAppSortDirection(_ direction: SimulatorFilters.SortDirection) {
    filters.appSortDirection = direction
    rebuildAfterFilterChange()
  }

  public mutating func clearAppFilters() {
    filters.appSystemFilter = .user
    filters.appGroupFilter = .all
    filters.appDatabaseFilter = .all
    rebuildAfterFilterChange()
  }

  public mutating func togglePinnedDevice(id: String) {
    if filters.pinnedDeviceIDs.contains(id) {
      filters.pinnedDeviceIDs.remove(id)
    } else {
      filters.pinnedDeviceIDs.insert(id)
    }

    rebuildAfterFilterChange(preferredSelectedDeviceID: id)
  }

  public mutating func togglePinnedApp(id: String) {
    if filters.pinnedAppIDs.contains(id) {
      filters.pinnedAppIDs.remove(id)
    } else {
      filters.pinnedAppIDs.insert(id)
    }

    rebuildAfterFilterChange(preferredSelectedAppID: id)
  }
}
