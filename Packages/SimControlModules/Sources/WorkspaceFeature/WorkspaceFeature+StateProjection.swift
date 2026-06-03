import DeviceDetailFeature
import SimControlDomain

// MARK: - WorkspaceFeature.State Projection

extension WorkspaceFeature.State {
  var inventoryQuery: SimulatorInventoryQuery? {
    guard let snapshot else {
      return nil
    }

    return SimulatorInventoryQuery(snapshot: snapshot, filters: filters)
  }

  var devices: [SimulatorDevice] {
    inventoryQuery?.devices ?? []
  }

  var runtimeByID: [String: SimulatorRuntime] {
    inventoryQuery?.runtimeByID ?? [:]
  }

  var deviceTypeByID: [String: SimulatorDeviceType] {
    inventoryQuery?.deviceTypeByID ?? [:]
  }

  public var selectedDevice: SimulatorDevice? {
    inventoryQuery?.device(id: deviceList.selectedDeviceID)
  }

  public var selectedRuntime: SimulatorRuntime? {
    inventoryQuery?.runtime(for: selectedDevice)
  }

  public var selectedDeviceType: SimulatorDeviceType? {
    inventoryQuery?.deviceType(for: selectedDevice)
  }

  public var selectedPairSummary: DeviceDetailFeature.DevicePairSummary? {
    guard let summary = inventoryQuery?.pairSummary(for: selectedDevice) else {
      return nil
    }

    return DeviceDetailFeature.DevicePairSummary(
      id: summary.id,
      phoneDeviceID: summary.phoneDeviceID,
      phoneName: summary.phoneName,
      phoneUDID: summary.phoneUDID,
      watchDeviceID: summary.watchDeviceID,
      watchName: summary.watchName,
      watchUDID: summary.watchUDID,
      state: summary.state
    )
  }
}
