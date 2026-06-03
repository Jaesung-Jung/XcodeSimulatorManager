import DeviceDetailFeature
import DeviceListFeature
import InspectorFeature
import InstalledAppsFeature
import SimControlDomain

// MARK: - WorkspaceFeature.State Rebuild

extension WorkspaceFeature.State {
  mutating func rebuildDeviceList(selectedDeviceID: String?) {
    deviceList = DeviceListFeature.State(
      devices: inventoryQuery?.visibleDevices() ?? [],
      runtimeByID: inventoryQuery?.runtimeByID ?? [:],
      deviceTypeByID: inventoryQuery?.deviceTypeByID ?? [:],
      installedAppsByDeviceID: inventoryQuery?.visibleInstalledAppsByDeviceID() ?? [:],
      installedAppsAvailability: installedAppsAvailability,
      selectedDeviceID: selectedDeviceID,
      filters: filters,
      totalDeviceCount: devices.count
    )
  }

  mutating func rebuildDetail(selectedAppID: String?) {
    let allInstalledApps = selectedDevice.map { device in
      snapshot?.installedAppsByDeviceID[device.id] ?? []
    } ?? []
    let installedApps = selectedDevice.map {
      inventoryQuery?.visibleApps(for: $0.id) ?? []
    } ?? []
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
        compatibleInstallTargetCount: inventoryQuery?.compatibleInstallTargetCount(for: selectedDevice) ?? 0,
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

  mutating func rebuildInspector() {
    inspector = InspectorFeature.State(
      snapshot: snapshot,
      device: selectedDevice,
      runtime: selectedRuntime,
      deviceType: selectedDeviceType,
      selectedApp: deviceDetail.selectedApp
    )
  }

  mutating func rebuildAfterFilterChange(
    preferredSelectedDeviceID: String? = nil,
    preferredSelectedAppID: String? = nil
  ) {
    let selection = inventoryQuery?.selectionAfterFilterChange(
      current: SimulatorInventorySelection(
        deviceID: deviceList.selectedDeviceID,
        appID: deviceDetail.installedApps.selectedAppID
      ),
      preferred: SimulatorInventorySelection(
        deviceID: preferredSelectedDeviceID,
        appID: preferredSelectedAppID
      )
    )

    rebuildDeviceList(selectedDeviceID: selection?.deviceID)
    rebuildDetail(selectedAppID: selection?.appID)
  }
}
