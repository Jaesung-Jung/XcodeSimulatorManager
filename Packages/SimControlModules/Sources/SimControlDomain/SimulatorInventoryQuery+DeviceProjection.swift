import Foundation

extension SimulatorInventoryQuery {
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
}
