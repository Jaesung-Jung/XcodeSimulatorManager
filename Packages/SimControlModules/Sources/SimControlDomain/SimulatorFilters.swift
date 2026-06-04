import Foundation

/// User-selected filters and sort options for simulator inventory projection.
public struct SimulatorFilters: Equatable {
  /// The sidebar grouping or filter currently applied to devices.
  public enum SidebarScope: Equatable, Hashable {
    case all
    case pinned
    case warnings
    case platform(SimulatorPlatform)
    case runtime(String)
    case state(SimulatorDevice.State)
  }

  /// A sort direction used by device and app lists.
  public enum SortDirection: Equatable, Hashable {
    case ascending
    case descending
  }

  /// Device list sort keys.
  public enum DeviceSort: Equatable, Hashable {
    case name
    case state
    case runtime
    case platform
    case lastBootedAt
    case dataSize
  }

  /// Installed app list sort keys.
  public enum AppSort: Equatable, Hashable {
    case name
    case bundleID
    case version
    case dataSize
  }

  /// Whether installed app lists show user apps, system apps, or both.
  public enum AppSystemFilter: Equatable, Hashable {
    case user
    case system
    case all
  }

  /// Whether an optional app-related value must be present, absent, or either.
  public enum PresenceFilter: Equatable, Hashable {
    case all
    case present
    case absent
  }

  private static let recentTargetLimit = 8

  public var searchQuery: String
  public var sidebarScope: SidebarScope
  public var deviceSort: DeviceSort
  public var deviceSortDirection: SortDirection
  public var appSystemFilter: AppSystemFilter
  public var showsHiddenSystemApps: Bool
  public var appGroupFilter: PresenceFilter
  public var appDatabaseFilter: PresenceFilter
  public var appSort: AppSort
  public var appSortDirection: SortDirection
  public var pinnedDeviceIDs: Set<String>
  public var pinnedAppIDs: Set<String>
  public var recentAppIDs: [String]

  /// Creates simulator inventory filters with app-focused defaults.
  public init(
    searchQuery: String = "",
    sidebarScope: SidebarScope = .all,
    deviceSort: DeviceSort = .name,
    deviceSortDirection: SortDirection = .ascending,
    appSystemFilter: AppSystemFilter = .all,
    showsHiddenSystemApps: Bool = false,
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
    self.deviceSort = deviceSort
    self.deviceSortDirection = deviceSortDirection
    self.appSystemFilter = appSystemFilter
    self.showsHiddenSystemApps = showsHiddenSystemApps
    self.appGroupFilter = appGroupFilter
    self.appDatabaseFilter = appDatabaseFilter
    self.appSort = appSort
    self.appSortDirection = appSortDirection
    self.pinnedDeviceIDs = pinnedDeviceIDs
    self.pinnedAppIDs = pinnedAppIDs
    self.recentAppIDs = Self.deduplicatedRecentIDs(recentAppIDs)
  }

  /// The search query with surrounding whitespace removed.
  public var trimmedSearchQuery: String {
    searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  /// Whether the current search query contains non-whitespace text.
  public var hasSearchQuery: Bool {
    !trimmedSearchQuery.isEmpty
  }

  /// Whether app-specific filters differ from the default user-app view.
  public var hasActiveAppFilters: Bool {
    appSystemFilter != .all
      || showsHiddenSystemApps
      || appGroupFilter != .all
      || appDatabaseFilter != .all
  }

  /// Records a recently selected app identifier, keeping the most recent value first.
  public mutating func recordRecentAppID(_ id: String) {
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
