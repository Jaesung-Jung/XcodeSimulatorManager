import Foundation

extension SimulatorInventoryQuery {
  func filteredDevices(_ devices: [SimulatorDevice]) -> [SimulatorDevice] {
    devices.filter { device in
      deviceMatchesSidebarScope(device)
        && deviceMatchesSearch(device)
    }
  }

  func deviceMatchesSidebarScope(_ device: SimulatorDevice) -> Bool {
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

  func deviceMatchesSearch(_ device: SimulatorDevice) -> Bool {
    let query = filters.trimmedSearchQuery
    guard !query.isEmpty else {
      return true
    }

    if matches(query, in: deviceSearchCandidates(device)) {
      return true
    }

    return !filteredApps(snapshot.installedAppsByDeviceID[device.id] ?? []).isEmpty
  }

  func deviceSearchCandidates(_ device: SimulatorDevice) -> [String] {
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
}
