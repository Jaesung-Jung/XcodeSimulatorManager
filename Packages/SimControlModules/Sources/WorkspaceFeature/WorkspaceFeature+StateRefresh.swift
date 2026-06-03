import DeviceDetailFeature
import InstalledAppsFeature
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - WorkspaceFeature.State Refresh

extension WorkspaceFeature.State {
  public mutating func setRefreshState(_ refreshState: InventoryRefreshState) {
    self.refreshState = refreshState
  }

  public mutating func applyRefreshFailure(
    _ refreshState: InventoryRefreshState,
    commandResults: [CommandResult]
  ) {
    self.refreshState = refreshState
    self.commandResults = commandResults
    deviceDetail.commandResults = commandResults
  }

  public mutating func applySnapshot(
    _ snapshot: SimulatorSnapshot,
    refreshState: InventoryRefreshState,
    commandResults: [CommandResult],
    preferredSelectedDeviceID: String? = nil,
    preferredSelectedAppID: String? = nil
  ) {
    self.snapshot = snapshot

    let selection = inventoryQuery?.selectionAfterApplyingSnapshot(
      current: SimulatorInventorySelection(
        deviceID: deviceList.selectedDeviceID,
        appID: deviceDetail.installedApps.selectedAppID
      ),
      preferred: SimulatorInventorySelection(
        deviceID: preferredSelectedDeviceID,
        appID: preferredSelectedAppID
      )
    )

    self.refreshState = refreshState
    self.commandResults = commandResults
    installedAppsAvailability = .loaded
    rebuildDeviceList(selectedDeviceID: selection?.deviceID)
    rebuildDetail(selectedAppID: selection?.appID)
  }

  public mutating func appendCommandResult(_ result: CommandResult) {
    commandResults.append(result)
    deviceDetail.commandResults = commandResults
  }
}
