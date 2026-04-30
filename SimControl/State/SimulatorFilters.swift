import Foundation

struct SimulatorFilters: Equatable {
  enum SidebarScope: Equatable, Hashable {
    case all
    case pinned
    case warnings
    case platform(SimulatorPlatform)
    case runtime(String)
    case state(SimulatorDevice.State)
  }

  enum SortDirection: Equatable, Hashable {
    case ascending
    case descending
  }

  enum DeviceSort: Equatable, Hashable {
    case name
    case state
    case runtime
    case platform
    case lastBootedAt
    case dataSize
  }

  enum AppSort: Equatable, Hashable {
    case name
    case bundleID
    case version
    case dataSize
  }

  enum DeviceAvailabilityFilter: Equatable, Hashable {
    case all
    case available
    case unavailable
  }

  enum DeviceAppPresenceFilter: Equatable, Hashable {
    case all
    case hasApps
    case noApps
  }

  enum AppSystemFilter: Equatable, Hashable {
    case user
    case system
    case all
  }

  enum PresenceFilter: Equatable, Hashable {
    case all
    case present
    case absent
  }

  private static let recentTargetLimit = 8

  var searchQuery: String
  var sidebarScope: SidebarScope
  var deviceAvailabilityFilter: DeviceAvailabilityFilter
  var deviceAppPresenceFilter: DeviceAppPresenceFilter
  var deviceSort: DeviceSort
  var deviceSortDirection: SortDirection
  var appSystemFilter: AppSystemFilter
  var appGroupFilter: PresenceFilter
  var appDatabaseFilter: PresenceFilter
  var appSort: AppSort
  var appSortDirection: SortDirection
  var pinnedDeviceIDs: Set<String>
  var pinnedAppIDs: Set<String>
  var recentAppIDs: [String]

  init(
    searchQuery: String = "",
    sidebarScope: SidebarScope = .all,
    deviceAvailabilityFilter: DeviceAvailabilityFilter = .all,
    deviceAppPresenceFilter: DeviceAppPresenceFilter = .all,
    deviceSort: DeviceSort = .name,
    deviceSortDirection: SortDirection = .ascending,
    appSystemFilter: AppSystemFilter = .user,
    appGroupFilter: PresenceFilter = .all,
    appDatabaseFilter: PresenceFilter = .all,
    appSort: AppSort = .name,
    appSortDirection: SortDirection = .ascending,
    pinnedDeviceIDs: Set<String> = [],
    pinnedAppIDs: Set<String> = [],
    recentAppIDs: [String] = []
  ) {
    self.searchQuery = searchQuery
    self.sidebarScope = sidebarScope
    self.deviceAvailabilityFilter = deviceAvailabilityFilter
    self.deviceAppPresenceFilter = deviceAppPresenceFilter
    self.deviceSort = deviceSort
    self.deviceSortDirection = deviceSortDirection
    self.appSystemFilter = appSystemFilter
    self.appGroupFilter = appGroupFilter
    self.appDatabaseFilter = appDatabaseFilter
    self.appSort = appSort
    self.appSortDirection = appSortDirection
    self.pinnedDeviceIDs = pinnedDeviceIDs
    self.pinnedAppIDs = pinnedAppIDs
    self.recentAppIDs = Self.deduplicatedRecentIDs(recentAppIDs)
  }

  var trimmedSearchQuery: String {
    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var hasSearchQuery: Bool {
    !trimmedSearchQuery.isEmpty
  }

  var hasActiveDeviceFilters: Bool {
    sidebarScope != .all
      || deviceAvailabilityFilter != .all
      || deviceAppPresenceFilter != .all
  }

  var hasActiveAppFilters: Bool {
    appSystemFilter != .user
      || appGroupFilter != .all
      || appDatabaseFilter != .all
  }

  mutating func recordRecentAppID(_ id: String) {
    recentAppIDs = Self.recentIDs(afterRecording: id, in: recentAppIDs)
  }

  private static func recentIDs(afterRecording id: String, in ids: [String]) -> [String] {
    guard !id.isEmpty else {
      return ids
    }

    var updatedIDs = ids.filter { $0 != id }
    updatedIDs.insert(id, at: 0)
    return Array(updatedIDs.prefix(recentTargetLimit))
  }

  private static func deduplicatedRecentIDs(_ ids: [String]) -> [String] {
    var seenIDs = Set<String>()
    var deduplicatedIDs: [String] = []

    for id in ids where !id.isEmpty && !seenIDs.contains(id) {
      seenIDs.insert(id)
      deduplicatedIDs.append(id)
    }

    return Array(deduplicatedIDs.prefix(recentTargetLimit))
  }
}
