import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature Device Helpers

extension MainWindowFeature {
  func device(id: String, in state: State) -> SimulatorDevice? {
    state.workspace.snapshot?.devices.first { $0.id == id }
  }

  func deviceDestructiveConfirmationState(
    deviceID: String,
    in state: State
  ) -> DeviceDestructiveConfirmationState? {
    guard let device = device(id: deviceID, in: state) else {
      return nil
    }

    return DeviceDestructiveConfirmationState(
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid
    )
  }

  func unpairConfirmationState(
    pairID: String,
    in state: State
  ) -> UnpairDeviceConfirmationState? {
    guard let snapshot = state.workspace.snapshot,
          let pair = snapshot.pairs.first(where: { $0.id == pairID }),
          let phoneDevice = snapshot.devices.first(where: { $0.id == pair.phoneDeviceID }),
          let watchDevice = snapshot.devices.first(where: { $0.id == pair.watchDeviceID })
    else {
      return nil
    }

    return UnpairDeviceConfirmationState(
      pairID: pair.id,
      phoneName: phoneDevice.name,
      phoneUDID: phoneDevice.udid,
      watchName: watchDevice.name,
      watchUDID: watchDevice.udid
    )
  }

  func canRun(
    _ command: DeviceCommand,
    on device: SimulatorDevice
  ) -> Bool {
    guard device.isAvailable else {
      return false
    }

    switch command {
    case .boot:
      return device.state == .shutdown
    case .shutdown:
      return device.state == .booted
    case .create,
         .clone,
         .rename,
         .erase,
         .delete,
         .pair,
         .unpair,
         .openURL,
         .pushNotification,
         .privacyPermission,
         .setLocation,
         .clearLocation,
         .statusBarOverride,
         .clearStatusBarOverride:
      return false
    }
  }

  func compatibleDeviceTypes(
    for runtime: SimulatorRuntime,
    in deviceTypes: [SimulatorDeviceType]
  ) -> [SimulatorDeviceType] {
    guard !runtime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }
}
