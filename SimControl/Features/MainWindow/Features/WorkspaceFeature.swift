import ComposableArchitecture
import Foundation

@Reducer
struct WorkspaceFeature {
  @ObservableState
  struct State: Equatable {
    var snapshot: SimulatorSnapshot?
    var refreshState: InventoryRefreshState
    var filters: SimulatorFilters
    var deviceList: DeviceListFeature.State
    var deviceDetail: DeviceDetailFeature.State
    var inspector: InspectorFeature.State
    var commandResults: [CommandResult]
    var installedAppsAvailability: InstalledAppsAvailability
    var deviceCommandState: DeviceCommandState?
    var appCommandState: AppCommandState?
    var isOpeningSimulatorApp: Bool

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      selectedDeviceID: String? = nil,
      selectedAppID: String? = nil,
      commandResults: [CommandResult] = [],
      installedAppsAvailability: InstalledAppsAvailability? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      isOpeningSimulatorApp: Bool = false,
      filters: SimulatorFilters = SimulatorFilters()
    ) {
      self.snapshot = snapshot
      self.refreshState = refreshState
      self.filters = filters
      self.deviceList = DeviceListFeature.State()
      self.deviceDetail = DeviceDetailFeature.State()
      self.inspector = InspectorFeature.State(snapshot: snapshot)
      self.commandResults = commandResults
      self.installedAppsAvailability = installedAppsAvailability ?? (snapshot == nil ? .notLoaded : .loaded)
      self.deviceCommandState = deviceCommandState
      self.appCommandState = appCommandState
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
      rebuildDeviceList(selectedDeviceID: selectedDeviceID)
      rebuildDetail(selectedAppID: selectedAppID)
    }

    mutating func setRefreshState(_ refreshState: InventoryRefreshState) {
      self.refreshState = refreshState
    }

    mutating func applyRefreshFailure(
      _ refreshState: InventoryRefreshState,
      commandResults: [CommandResult]
    ) {
      self.refreshState = refreshState
      self.commandResults = commandResults
      deviceDetail.commandResults = commandResults
    }

    mutating func applySnapshot(
      _ snapshot: SimulatorSnapshot,
      refreshState: InventoryRefreshState,
      commandResults: [CommandResult],
      preferredSelectedDeviceID: String? = nil,
      preferredSelectedAppID: String? = nil
    ) {
      let previousSelectedDeviceID = deviceList.selectedDeviceID
      self.snapshot = snapshot

      let selectedDeviceID = validPreferredSelectedDeviceID(preferredSelectedDeviceID)
        ?? validSelectedDeviceID()
      let selectedAppID = validPreferredSelectedAppID(
        preferredSelectedAppID,
        selectedDeviceID: selectedDeviceID
      ) ?? (
        selectedDeviceID == previousSelectedDeviceID
          ? validPreferredSelectedAppID(
            deviceDetail.installedApps.selectedAppID,
            selectedDeviceID: selectedDeviceID
          )
          : nil
      )

      self.refreshState = refreshState
      self.commandResults = commandResults
      installedAppsAvailability = .loaded
      rebuildDeviceList(selectedDeviceID: selectedDeviceID)
      rebuildDetail(selectedAppID: selectedAppID)
    }

    mutating func selectDevice(id: String?) {
      guard deviceList.selectedDeviceID != id else {
        return
      }

      if let id {
        guard devices.contains(where: { $0.id == id }) else {
          return
        }

        filters.recordRecentDeviceID(id)
      }

      deviceList.selectedDeviceID = id
      rebuildDeviceList(selectedDeviceID: id)
      rebuildDetail(selectedAppID: nil)
    }

    mutating func selectApp(id: String?) {
      if let id {
        guard deviceDetail.installedApps.apps.contains(where: { $0.id == id }) else {
          return
        }

        filters.recordRecentAppID(id)
      }

      rebuildDetail(selectedAppID: id)
    }

    mutating func setSearchQuery(_ query: String) {
      filters.searchQuery = query
      let searchTarget = exactSearchTarget()
      rebuildAfterFilterChange(
        preferredSelectedDeviceID: searchTarget.deviceID,
        preferredSelectedAppID: searchTarget.appID
      )
    }

    mutating func setSidebarScope(_ scope: SimulatorFilters.SidebarScope) {
      filters.sidebarScope = scope
      rebuildAfterFilterChange()
    }

    mutating func setDeviceAvailabilityFilter(_ filter: SimulatorFilters.DeviceAvailabilityFilter) {
      filters.deviceAvailabilityFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setDeviceAppPresenceFilter(_ filter: SimulatorFilters.DeviceAppPresenceFilter) {
      filters.deviceAppPresenceFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setDeviceSort(_ sort: SimulatorFilters.DeviceSort) {
      filters.deviceSort = sort
      rebuildAfterFilterChange()
    }

    mutating func setDeviceSortDirection(_ direction: SimulatorFilters.SortDirection) {
      filters.deviceSortDirection = direction
      rebuildAfterFilterChange()
    }

    mutating func clearDeviceFilters() {
      filters.sidebarScope = .all
      filters.deviceAvailabilityFilter = .all
      filters.deviceAppPresenceFilter = .all
      rebuildAfterFilterChange()
    }

    mutating func setAppSystemFilter(_ filter: SimulatorFilters.AppSystemFilter) {
      filters.appSystemFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setAppGroupFilter(_ filter: SimulatorFilters.PresenceFilter) {
      filters.appGroupFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setAppDatabaseFilter(_ filter: SimulatorFilters.PresenceFilter) {
      filters.appDatabaseFilter = filter
      rebuildAfterFilterChange()
    }

    mutating func setAppSort(_ sort: SimulatorFilters.AppSort) {
      filters.appSort = sort
      rebuildAfterFilterChange()
    }

    mutating func setAppSortDirection(_ direction: SimulatorFilters.SortDirection) {
      filters.appSortDirection = direction
      rebuildAfterFilterChange()
    }

    mutating func clearAppFilters() {
      filters.appSystemFilter = .user
      filters.appGroupFilter = .all
      filters.appDatabaseFilter = .all
      rebuildAfterFilterChange()
    }

    mutating func togglePinnedDevice(id: String) {
      if filters.pinnedDeviceIDs.contains(id) {
        filters.pinnedDeviceIDs.remove(id)
      } else {
        filters.pinnedDeviceIDs.insert(id)
      }

      rebuildAfterFilterChange(preferredSelectedDeviceID: id)
    }

    mutating func togglePinnedApp(id: String) {
      if filters.pinnedAppIDs.contains(id) {
        filters.pinnedAppIDs.remove(id)
      } else {
        filters.pinnedAppIDs.insert(id)
      }

      rebuildAfterFilterChange(preferredSelectedAppID: id)
    }

    mutating func appendCommandResult(_ result: CommandResult) {
      commandResults.append(result)
      deviceDetail.commandResults = commandResults
    }

    mutating func setDeviceCommandState(_ deviceCommandState: DeviceCommandState?) {
      self.deviceCommandState = deviceCommandState
      deviceDetail.deviceCommandState = deviceCommandState
      deviceDetail.installedApps.isDeviceCommandRunning = deviceCommandState != nil
      deviceDetail.developerTools.deviceCommandState = deviceCommandState
    }

    mutating func setAppCommandState(_ appCommandState: AppCommandState?) {
      self.appCommandState = appCommandState
      deviceDetail.appCommandState = appCommandState
      deviceDetail.installedApps.appCommandState = appCommandState
      deviceDetail.developerTools.appCommandState = appCommandState
    }

    mutating func setOpeningSimulatorApp(_ isOpeningSimulatorApp: Bool) {
      self.isOpeningSimulatorApp = isOpeningSimulatorApp
      deviceDetail.isOpeningSimulatorApp = isOpeningSimulatorApp
    }

    private mutating func rebuildDeviceList(selectedDeviceID: String?) {
      deviceList = DeviceListFeature.State(
        devices: visibleDevices,
        runtimeByID: runtimeByID,
        deviceTypeByID: deviceTypeByID,
        installedAppsByDeviceID: visibleInstalledAppsByDeviceID,
        installedAppsAvailability: installedAppsAvailability,
        selectedDeviceID: selectedDeviceID,
        filters: filters,
        totalDeviceCount: devices.count
      )
    }

    private mutating func rebuildDetail(selectedAppID: String?) {
      let allInstalledApps = selectedDevice.map { device in
        snapshot?.installedAppsByDeviceID[device.id] ?? []
      } ?? []
      let installedApps = selectedDevice.map(visibleApps) ?? []
      var developerTools = deviceDetail.developerTools
      developerTools.updateContext(
        device: selectedDevice,
        installedApps: allInstalledApps,
        selectedAppID: selectedAppID,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState
      )

      deviceDetail = DeviceDetailFeature.State(
        device: selectedDevice,
        runtime: selectedRuntime,
        deviceType: selectedDeviceType,
        pairSummary: selectedPairSummary,
        installedApps: InstalledAppsFeature.State(
          apps: installedApps,
          availability: installedAppsAvailability,
          device: selectedDevice,
          selectedAppID: selectedAppID,
          appCommandState: appCommandState,
          isDeviceCommandRunning: deviceCommandState != nil,
          compatibleInstallTargetCount: compatibleInstallTargetCount(for: selectedDevice),
          filters: filters,
          allAppsCount: allInstalledApps.count
        ),
        commandResults: commandResults,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp,
        developerTools: developerTools
      )
      rebuildInspector()
    }

    private mutating func rebuildInspector() {
      inspector = InspectorFeature.State(
        snapshot: snapshot,
        device: selectedDevice,
        runtime: selectedRuntime,
        deviceType: selectedDeviceType,
        selectedApp: deviceDetail.selectedApp
      )
    }

    private func validSelectedDeviceID() -> String? {
      guard let selectedDeviceID = deviceList.selectedDeviceID else {
        return nil
      }

      return visibleDevices.contains(where: { $0.id == selectedDeviceID })
        ? selectedDeviceID
        : nil
    }

    private func validPreferredSelectedDeviceID(
      _ preferredSelectedDeviceID: String?
    ) -> String? {
      guard let preferredSelectedDeviceID else {
        return nil
      }

      return visibleDevices.contains(where: { $0.id == preferredSelectedDeviceID })
        ? preferredSelectedDeviceID
        : nil
    }

    private func validPreferredSelectedAppID(
      _ preferredSelectedAppID: String?,
      selectedDeviceID: String?
    ) -> String? {
      guard let preferredSelectedAppID,
            let selectedDeviceID,
            let selectedDevice = devices.first(where: { $0.id == selectedDeviceID }),
            visibleApps(for: selectedDevice).contains(where: {
              $0.id == preferredSelectedAppID
            }) == true
      else {
        return nil
      }

      return preferredSelectedAppID
    }

    private mutating func rebuildAfterFilterChange(
      preferredSelectedDeviceID: String? = nil,
      preferredSelectedAppID: String? = nil
    ) {
      let selectedDeviceID = validPreferredSelectedDeviceID(preferredSelectedDeviceID)
        ?? validSelectedDeviceID()
        ?? visibleDevices.first?.id
      let selectedAppID = validPreferredSelectedAppID(
        preferredSelectedAppID,
        selectedDeviceID: selectedDeviceID
      ) ?? validPreferredSelectedAppID(
        deviceDetail.installedApps.selectedAppID,
        selectedDeviceID: selectedDeviceID
      )

      rebuildDeviceList(selectedDeviceID: selectedDeviceID)
      rebuildDetail(selectedAppID: selectedAppID)
    }

    private func visibleApps(for device: SimulatorDevice) -> [InstalledApp] {
      let apps = snapshot?.installedAppsByDeviceID[device.id] ?? []
      return sortedApps(filteredApps(apps))
    }

    private var visibleInstalledAppsByDeviceID: [String: [InstalledApp]] {
      guard let installedAppsByDeviceID = snapshot?.installedAppsByDeviceID else {
        return [:]
      }

      return installedAppsByDeviceID.mapValues { filteredApps($0) }
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

    private func presence(_ isEmpty: Bool, matches filter: SimulatorFilters.PresenceFilter) -> Bool {
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

    private func appComparison(_ first: InstalledApp, _ second: InstalledApp) -> ComparisonResult {
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

    private var visibleDevices: [SimulatorDevice] {
      sortedDevices(filteredDevices(devices))
    }

    private func filteredDevices(_ devices: [SimulatorDevice]) -> [SimulatorDevice] {
      devices.filter { device in
        deviceMatchesSidebarScope(device)
          && deviceMatchesAvailabilityFilter(device)
          && deviceMatchesAppPresenceFilter(device)
          && deviceMatchesSearch(device)
      }
    }

    private func deviceMatchesSidebarScope(_ device: SimulatorDevice) -> Bool {
      switch filters.sidebarScope {
      case .all:
        true
      case .pinned:
        filters.pinnedDeviceIDs.contains(device.id)
      case .recent:
        filters.recentDeviceIDs.contains(device.id)
      case .warnings:
        snapshot?.warnings.contains { $0.relatedID == device.id } == true
      case .platform(let platform):
        device.platform == platform
      case .runtime(let runtimeID):
        device.runtimeID == runtimeID
      case .state(let state):
        device.state == state
      }
    }

    private func deviceMatchesAvailabilityFilter(_ device: SimulatorDevice) -> Bool {
      switch filters.deviceAvailabilityFilter {
      case .all:
        true
      case .available:
        device.isAvailable
      case .unavailable:
        !device.isAvailable
      }
    }

    private func deviceMatchesAppPresenceFilter(_ device: SimulatorDevice) -> Bool {
      let apps = filteredApps(snapshot?.installedAppsByDeviceID[device.id] ?? [])
      switch filters.deviceAppPresenceFilter {
      case .all:
        return true
      case .hasApps:
        return !apps.isEmpty
      case .noApps:
        return apps.isEmpty
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

      return !filteredApps(snapshot?.installedAppsByDeviceID[device.id] ?? []).isEmpty
    }

    private func deviceSearchCandidates(_ device: SimulatorDevice) -> [String] {
      var candidates = [
        device.id,
        device.udid,
        device.name,
        device.platform.displayTitle,
        device.state.displayTitle,
        device.runtimeID,
        device.deviceTypeID
      ]

      if let runtime = runtimeByID[device.runtimeID] {
        candidates.append(contentsOf: [
          runtime.id,
          runtime.name,
          runtime.version,
          runtime.buildVersion,
          runtime.platform.displayTitle
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

    private func deviceComparison(_ first: SimulatorDevice, _ second: SimulatorDevice) -> ComparisonResult {
      switch filters.deviceSort {
      case .name:
        return first.name.localizedStandardCompare(second.name)
      case .state:
        return first.state.displayTitle.localizedStandardCompare(second.state.displayTitle)
      case .runtime:
        return (runtimeByID[first.runtimeID]?.name ?? first.runtimeID)
          .localizedStandardCompare(runtimeByID[second.runtimeID]?.name ?? second.runtimeID)
      case .platform:
        return first.platform.displayTitle.localizedStandardCompare(second.platform.displayTitle)
      case .lastBootedAt:
        return compare(first.lastBootedAt?.timeIntervalSince1970 ?? -1, second.lastBootedAt?.timeIntervalSince1970 ?? -1)
      case .dataSize:
        return compare(first.dataPathSize ?? -1, second.dataPathSize ?? -1)
      }
    }

    private func exactSearchTarget() -> (deviceID: String?, appID: String?) {
      let query = filters.trimmedSearchQuery
      guard !query.isEmpty else {
        return (nil, nil)
      }

      if let device = devices.first(where: {
        $0.udid.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
          || $0.id.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
      }) {
        return (device.id, nil)
      }

      for apps in (snapshot?.installedAppsByDeviceID ?? [:]).values {
        if let app = apps.first(where: {
          $0.bundleID.compare(query, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame
        }) {
          return (app.deviceID, app.id)
        }
      }

      return (nil, nil)
    }

    private func matches(_ query: String, in candidates: [String]) -> Bool {
      candidates.contains {
        $0.range(of: query, options: [.caseInsensitive, .diacriticInsensitive]) != nil
      }
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

    private func compatibleInstallTargetCount(for sourceDevice: SimulatorDevice?) -> Int {
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

    private var devices: [SimulatorDevice] {
      snapshot?.devices ?? []
    }

    private var runtimeByID: [String: SimulatorRuntime] {
      Dictionary(uniqueKeysWithValues: (snapshot?.runtimes ?? []).map { ($0.id, $0) })
    }

    private var deviceTypeByID: [String: SimulatorDeviceType] {
      Dictionary(uniqueKeysWithValues: (snapshot?.deviceTypes ?? []).map { ($0.id, $0) })
    }

    private var deviceByID: [String: SimulatorDevice] {
      Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) })
    }

    var selectedDevice: SimulatorDevice? {
      guard let selectedDeviceID = deviceList.selectedDeviceID else {
        return nil
      }

      return devices.first { $0.id == selectedDeviceID }
    }

    var selectedRuntime: SimulatorRuntime? {
      guard let selectedDevice else {
        return nil
      }

      return runtimeByID[selectedDevice.runtimeID]
    }

    var selectedDeviceType: SimulatorDeviceType? {
      guard let selectedDevice else {
        return nil
      }

      return deviceTypeByID[selectedDevice.deviceTypeID]
    }

    var selectedPairSummary: DeviceDetailFeature.DevicePairSummary? {
      guard let selectedDevice, let snapshot else {
        return nil
      }

      let selectedDeviceID = selectedDevice.id
      guard let pair = snapshot.pairs.first(where: {
        $0.phoneDeviceID == selectedDeviceID || $0.watchDeviceID == selectedDeviceID
      }),
        let phoneDevice = deviceByID[pair.phoneDeviceID],
        let watchDevice = deviceByID[pair.watchDeviceID]
      else {
        return nil
      }

      return DeviceDetailFeature.DevicePairSummary(
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
  }

  enum Action: Equatable {
    case searchQueryChanged(String)
    case sidebarScopeChanged(SimulatorFilters.SidebarScope)
    case deviceList(DeviceListFeature.Action)
    case deviceDetail(DeviceDetailFeature.Action)
    case inspector(InspectorFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .searchQueryChanged(let query):
        state.setSearchQuery(query)
        return .none

      case .sidebarScopeChanged(let scope):
        state.setSidebarScope(scope)
        return .none

      case .deviceList(.selectionChanged(let id)):
        state.selectDevice(id: id)
        return .none

      case .deviceList(.pinButtonTapped(let id)):
        state.togglePinnedDevice(id: id)
        return .none

      case .deviceList(.deviceAvailabilityFilterChanged(let filter)):
        state.setDeviceAvailabilityFilter(filter)
        return .none

      case .deviceList(.deviceAppPresenceFilterChanged(let filter)):
        state.setDeviceAppPresenceFilter(filter)
        return .none

      case .deviceList(.deviceSortChanged(let sort)):
        state.setDeviceSort(sort)
        return .none

      case .deviceList(.deviceSortDirectionChanged(let direction)):
        state.setDeviceSortDirection(direction)
        return .none

      case .deviceList(.clearDeviceFiltersButtonTapped):
        state.clearDeviceFilters()
        return .none

      case .deviceDetail(.installedApps(.selectionChanged(let id))):
        state.selectApp(id: id)
        return .none

      case .deviceDetail(.installedApps(.pinButtonTapped(let id))):
        state.togglePinnedApp(id: id)
        return .none

      case .deviceDetail(.installedApps(.appSystemFilterChanged(let filter))):
        state.setAppSystemFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appGroupFilterChanged(let filter))):
        state.setAppGroupFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appDatabaseFilterChanged(let filter))):
        state.setAppDatabaseFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appSortChanged(let sort))):
        state.setAppSort(sort)
        return .none

      case .deviceDetail(.installedApps(.appSortDirectionChanged(let direction))):
        state.setAppSortDirection(direction)
        return .none

      case .deviceDetail(.installedApps(.clearAppFiltersButtonTapped)):
        state.clearAppFilters()
        return .none

      case .deviceDetail, .inspector:
        return .none
      }
    }

    Scope(state: \.deviceList, action: \.deviceList) {
      DeviceListFeature()
    }
    Scope(state: \.deviceDetail, action: \.deviceDetail) {
      DeviceDetailFeature()
    }
    Scope(state: \.inspector, action: \.inspector) {
      InspectorFeature()
    }
  }
}
