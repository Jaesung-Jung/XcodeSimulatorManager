import Foundation

extension SimulatorInventoryQuery {
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
}
