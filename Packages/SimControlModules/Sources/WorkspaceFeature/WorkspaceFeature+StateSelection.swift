import SimControlDomain

// MARK: - WorkspaceFeature.State Selection

extension WorkspaceFeature.State {
  public mutating func selectDevice(id: String?) {
    guard deviceList.selectedDeviceID != id else {
      return
    }

    if let id {
      guard devices.contains(where: { $0.id == id }) else {
        return
      }
    }

    deviceList.selectedDeviceID = id
    rebuildDeviceList(selectedDeviceID: id)
    rebuildDetail(selectedAppID: nil)
  }

  public mutating func selectApp(id: String?) {
    if let id {
      guard deviceDetail.installedApps.apps.contains(where: { $0.id == id }) else {
        return
      }

      filters.recordRecentAppID(id)
    }

    rebuildDetail(selectedAppID: id)
  }
}
