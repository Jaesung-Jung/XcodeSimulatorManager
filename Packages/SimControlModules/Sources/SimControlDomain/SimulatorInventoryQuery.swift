import Foundation

/// A pure query object that projects simulator inventory for feature state.
///
/// `SimulatorInventoryQuery` owns filtering, sorting, exact-search navigation,
/// and selected-target reconciliation. It does not create feature state, run
/// commands, access files, or import UI frameworks.
public struct SimulatorInventoryQuery: Equatable {
  /// The simulator inventory snapshot being projected.
  public var snapshot: SimulatorSnapshot

  /// The filter and sort options used to project the snapshot.
  public var filters: SimulatorFilters

  /// Creates an inventory query for a snapshot and filter set.
  public init(snapshot: SimulatorSnapshot, filters: SimulatorFilters) {
    self.snapshot = snapshot
    self.filters = filters
  }

  /// All devices from the snapshot.
  public var devices: [SimulatorDevice] {
    snapshot.devices
  }

  /// Runtimes keyed by runtime identifier.
  public var runtimeByID: [String: SimulatorRuntime] {
    Dictionary(uniqueKeysWithValues: snapshot.runtimes.map { ($0.id, $0) })
  }

  /// Device types keyed by device type identifier.
  public var deviceTypeByID: [String: SimulatorDeviceType] {
    Dictionary(uniqueKeysWithValues: snapshot.deviceTypes.map { ($0.id, $0) })
  }

  /// Devices keyed by device identifier.
  public var deviceByID: [String: SimulatorDevice] {
    Dictionary(uniqueKeysWithValues: snapshot.devices.map { ($0.id, $0) })
  }

  /// Returns the visible devices after sidebar, search, pinning, and sort rules.
  public func visibleDevices() -> [SimulatorDevice] {
    sortedDevices(filteredDevices(devices))
  }

  /// Returns visible apps for a device after app filters, search, pinning, and sort rules.
  public func visibleApps(for deviceID: String) -> [InstalledApp] {
    sortedApps(filteredApps(snapshot.installedAppsByDeviceID[deviceID] ?? []))
  }

  /// Returns visible installed apps grouped by device identifier.
  public func visibleInstalledAppsByDeviceID() -> [String: [InstalledApp]] {
    snapshot.installedAppsByDeviceID.mapValues { filteredApps($0) }
  }

  /// Returns a device by identifier.
  public func device(id: String?) -> SimulatorDevice? {
    guard let id else {
      return nil
    }

    return deviceByID[id]
  }

  /// Returns the runtime for a device.
  public func runtime(for device: SimulatorDevice?) -> SimulatorRuntime? {
    guard let device else {
      return nil
    }

    return runtimeByID[device.runtimeID]
  }

  /// Returns the device type for a device.
  public func deviceType(for device: SimulatorDevice?) -> SimulatorDeviceType? {
    guard let device else {
      return nil
    }

    return deviceTypeByID[device.deviceTypeID]
  }

  /// Returns the paired phone/watch summary for a device, when one is available.
  public func pairSummary(for device: SimulatorDevice?) -> SimulatorInventoryPairSummary? {
    guard let device else {
      return nil
    }

    let selectedDeviceID = device.id
    guard let pair = snapshot.pairs.first(where: {
      $0.phoneDeviceID == selectedDeviceID || $0.watchDeviceID == selectedDeviceID
    }),
      let phoneDevice = deviceByID[pair.phoneDeviceID],
      let watchDevice = deviceByID[pair.watchDeviceID]
    else {
      return nil
    }

    return SimulatorInventoryPairSummary(
      id: pair.id,
      phoneDeviceID: phoneDevice.id,
      phoneName: phoneDevice.name,
      phoneUDID: phoneDevice.udid,
      watchDeviceID: watchDevice.id,
      watchName: watchDevice.name,
      watchUDID: watchDevice.udid,
      state: pair.state
    )
  }

  /// Returns the number of compatible target devices for app install operations.
  public func compatibleInstallTargetCount(for sourceDevice: SimulatorDevice?) -> Int {
    guard let sourceDevice else {
      return 0
    }

    return devices.filter { target in
      target.id != sourceDevice.id
        && target.isAvailable
        && target.platform == sourceDevice.platform
        && (target.state == .booted || target.state == .shutdown)
    }.count
  }

  /// Returns an exact-search navigation target for a device UDID/ID or app bundle ID.
  public func exactSearchTarget() -> SimulatorInventorySelection {
    let query = filters.trimmedSearchQuery
    guard !query.isEmpty else {
      return SimulatorInventorySelection()
    }

    if let device = devices.first(where: {
      same($0.udid, query) || same($0.id, query)
    }) {
      return SimulatorInventorySelection(deviceID: device.id)
    }

    for apps in snapshot.installedAppsByDeviceID.values {
      if let app = apps.first(where: { same($0.bundleID, query) }) {
        return SimulatorInventorySelection(deviceID: app.deviceID, appID: app.id)
      }
    }

    return SimulatorInventorySelection()
  }

  /// Reconciles selection after a new snapshot is applied.
  public func selectionAfterApplyingSnapshot(
    current: SimulatorInventorySelection,
    preferred: SimulatorInventorySelection
  ) -> SimulatorInventorySelection {
    let selectedDeviceID = validDeviceID(preferred.deviceID)
      ?? validDeviceID(current.deviceID)
    let selectedAppID = validAppID(
      preferred.appID,
      selectedDeviceID: selectedDeviceID
    ) ?? (
      selectedDeviceID == current.deviceID
        ? validAppID(current.appID, selectedDeviceID: selectedDeviceID)
        : nil
    )

    return SimulatorInventorySelection(deviceID: selectedDeviceID, appID: selectedAppID)
  }

  /// Reconciles selection after filters change, falling back to the first visible device.
  public func selectionAfterFilterChange(
    current: SimulatorInventorySelection,
    preferred: SimulatorInventorySelection
  ) -> SimulatorInventorySelection {
    let selectedDeviceID = validDeviceID(preferred.deviceID)
      ?? validDeviceID(current.deviceID)
      ?? visibleDevices().first?.id
    let selectedAppID = validAppID(
      preferred.appID,
      selectedDeviceID: selectedDeviceID
    ) ?? validAppID(
      current.appID,
      selectedDeviceID: selectedDeviceID
    )

    return SimulatorInventorySelection(deviceID: selectedDeviceID, appID: selectedAppID)
  }

  /// Returns a visible device identifier if it is still valid.
  public func validDeviceID(_ deviceID: String?) -> String? {
    guard let deviceID else {
      return nil
    }

    return visibleDevices().contains(where: { $0.id == deviceID }) ? deviceID : nil
  }

  /// Returns a visible app identifier if it is still valid for the selected device.
  public func validAppID(
    _ appID: String?,
    selectedDeviceID: String?
  ) -> String? {
    guard let appID,
          let selectedDeviceID,
          devices.contains(where: { $0.id == selectedDeviceID }),
          visibleApps(for: selectedDeviceID).contains(where: { $0.id == appID })
    else {
      return nil
    }

    return appID
  }

  private func filteredDevices(_ devices: [SimulatorDevice]) -> [SimulatorDevice] {
    devices.filter { device in
      deviceMatchesSidebarScope(device)
        && deviceMatchesSearch(device)
    }
  }

  private func deviceMatchesSidebarScope(_ device: SimulatorDevice) -> Bool {
    switch filters.sidebarScope {
    case .all:
      true
    case .pinned:
      filters.pinnedDeviceIDs.contains(device.id)
    case .warnings:
      snapshot.warnings.contains { $0.relatedID == device.id }
    case .platform(let platform):
      device.platform == platform
    case .runtime(let runtimeID):
      device.runtimeID == runtimeID
    case .state(let state):
      device.state == state
    }
  }

  private func deviceMatchesSearch(_ device: SimulatorDevice) -> Bool {
    let query = filters.trimmedSearchQuery
    guard !query.isEmpty else {
      return true
    }

    if matches(query, in: deviceSearchCandidates(device)) {
      return true
    }

    return !filteredApps(snapshot.installedAppsByDeviceID[device.id] ?? []).isEmpty
  }

  private func deviceSearchCandidates(_ device: SimulatorDevice) -> [String] {
    var candidates = [
      device.id,
      device.udid,
      device.name,
      device.platform.inventoryTitle,
      device.state.inventoryTitle,
      device.runtimeID,
      device.deviceTypeID
    ]

    if let runtime = runtimeByID[device.runtimeID] {
      candidates.append(contentsOf: [
        runtime.id,
        runtime.name,
        runtime.version,
        runtime.buildVersion,
        runtime.platform.inventoryTitle
      ])
    }

    if let deviceType = deviceTypeByID[device.deviceTypeID] {
      candidates.append(contentsOf: [
        deviceType.id,
        deviceType.name,
        deviceType.productFamily,
        deviceType.modelIdentifier
      ].compactMap { $0 })
    }

    candidates.append(contentsOf: [
      device.dataPath?.path,
      device.logPath?.path
    ].compactMap { $0 })

    return candidates
  }

  private func sortedDevices(_ devices: [SimulatorDevice]) -> [SimulatorDevice] {
    devices.sorted { first, second in
      let firstPinned = filters.pinnedDeviceIDs.contains(first.id)
      let secondPinned = filters.pinnedDeviceIDs.contains(second.id)
      if firstPinned != secondPinned {
        return firstPinned
      }

      let comparison = deviceComparison(first, second)
      if comparison == .orderedSame {
        return first.id.localizedStandardCompare(second.id) == .orderedAscending
      }

      return ordered(comparison, direction: filters.deviceSortDirection)
    }
  }

  private func deviceComparison(
    _ first: SimulatorDevice,
    _ second: SimulatorDevice
  ) -> ComparisonResult {
    switch filters.deviceSort {
    case .name:
      return first.name.localizedStandardCompare(second.name)
    case .state:
      return first.state.inventoryTitle.localizedStandardCompare(second.state.inventoryTitle)
    case .runtime:
      return (runtimeByID[first.runtimeID]?.name ?? first.runtimeID)
        .localizedStandardCompare(runtimeByID[second.runtimeID]?.name ?? second.runtimeID)
    case .platform:
      return first.platform.inventoryTitle.localizedStandardCompare(second.platform.inventoryTitle)
    case .lastBootedAt:
      return compare(
        first.lastBootedAt?.timeIntervalSince1970 ?? -1,
        second.lastBootedAt?.timeIntervalSince1970 ?? -1
      )
    case .dataSize:
      return compare(first.dataPathSize ?? -1, second.dataPathSize ?? -1)
    }
  }

  private func filteredApps(_ apps: [InstalledApp]) -> [InstalledApp] {
    apps.filter { app in
      appMatchesSystemFilter(app)
        && presence(app.appGroups.isEmpty, matches: filters.appGroupFilter)
        && presence(app.databaseFiles.isEmpty, matches: filters.appDatabaseFilter)
        && appMatchesSearch(app)
    }
  }

  private func appMatchesSystemFilter(_ app: InstalledApp) -> Bool {
    switch filters.appSystemFilter {
    case .user:
      !app.isSystemApp
    case .system:
      app.isSystemApp
    case .all:
      true
    }
  }

  private func presence(
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

  private func appMatchesSearch(_ app: InstalledApp) -> Bool {
    let query = filters.trimmedSearchQuery
    guard !query.isEmpty else {
      return true
    }

    return matches(query, in: appSearchCandidates(app))
  }

  private func appSearchCandidates(_ app: InstalledApp) -> [String] {
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

  private func sortedApps(_ apps: [InstalledApp]) -> [InstalledApp] {
    apps.sorted { first, second in
      let firstPinned = filters.pinnedAppIDs.contains(first.id)
      let secondPinned = filters.pinnedAppIDs.contains(second.id)
      if firstPinned != secondPinned {
        return firstPinned
      }

      let comparison = appComparison(first, second)
      if comparison == .orderedSame {
        return first.id.localizedStandardCompare(second.id) == .orderedAscending
      }

      return ordered(comparison, direction: filters.appSortDirection)
    }
  }

  private func appComparison(
    _ first: InstalledApp,
    _ second: InstalledApp
  ) -> ComparisonResult {
    switch filters.appSort {
    case .name:
      return first.displayName.localizedStandardCompare(second.displayName)
    case .bundleID:
      return first.bundleID.localizedStandardCompare(second.bundleID)
    case .version:
      return (first.version ?? "").localizedStandardCompare(second.version ?? "")
    case .dataSize:
      return compare(first.dataContainerSize ?? -1, second.dataContainerSize ?? -1)
    }
  }

  private func matches(_ query: String, in candidates: [String]) -> Bool {
    candidates.contains {
      $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
    }
  }

  private func same(_ candidate: String, _ query: String) -> Bool {
    candidate.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
  }

  private func ordered(
    _ comparison: ComparisonResult,
    direction: SimulatorFilters.SortDirection
  ) -> Bool {
    switch direction {
    case .ascending:
      comparison == .orderedAscending
    case .descending:
      comparison == .orderedDescending
    }
  }

  private func compare<T: Comparable>(_ first: T, _ second: T) -> ComparisonResult {
    if first < second {
      return .orderedAscending
    }

    if first > second {
      return .orderedDescending
    }

    return .orderedSame
  }
}

private extension SimulatorPlatform {
  var inventoryTitle: String {
    switch self {
    case .iOS:
      "iOS"
    case .watchOS:
      "watchOS"
    case .tvOS:
      "tvOS"
    case .visionOS:
      "visionOS"
    case .unknown:
      "Unknown"
    }
  }
}

private extension SimulatorDevice.State {
  var inventoryTitle: String {
    switch self {
    case .creating:
      "Creating"
    case .shutdown:
      "Shutdown"
    case .booting:
      "Booting"
    case .booted:
      "Booted"
    case .shuttingDown:
      "Shutting Down"
    case .unknown:
      "Unknown"
    }
  }
}
