import Foundation

extension SimulatorInventoryQuery {
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
}
