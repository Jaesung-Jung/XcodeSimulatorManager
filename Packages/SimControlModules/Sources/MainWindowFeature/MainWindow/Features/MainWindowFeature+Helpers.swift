import DeveloperToolsFeature
import Foundation
import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature Helpers

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

  func appCommandContext(
    appID: String,
    in state: State
  ) -> AppCommandContext? {
    guard let selectedDevice = state.workspace.selectedDevice,
          let app = state.workspace.snapshot?.installedAppsByDeviceID[selectedDevice.id]?
            .first(where: { $0.id == appID }),
          app.deviceID == selectedDevice.id
    else {
      return nil
    }

    return AppCommandContext(device: selectedDevice, app: app)
  }

  func appDestructiveConfirmationState(
    appID: String,
    in state: State,
    includesDataContainer: Bool
  ) -> AppDestructiveConfirmationState? {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return nil
    }

    return AppDestructiveConfirmationState(
      appID: context.app.id,
      appName: context.app.displayName,
      bundleID: context.app.bundleID,
      deviceID: context.device.id,
      deviceName: context.device.name,
      deviceUDID: context.device.udid,
      dataContainerPath: includesDataContainer ? context.app.dataContainer?.path : nil
    )
  }

  func installAppTargetFormState(
    appID: String,
    in state: State
  ) -> InstallAppTargetFormState? {
    guard let context = appCommandContext(appID: appID, in: state),
          let appBundlePath = context.app.appBundlePath,
          let targetDevice = installTargetCandidates(sourceDevice: context.device, in: state).first
    else {
      return nil
    }

    return InstallAppTargetFormState(
      sourceAppID: context.app.id,
      sourceDeviceID: context.device.id,
      appName: context.app.displayName,
      bundleID: context.app.bundleID,
      appBundlePath: appBundlePath,
      targetDeviceID: targetDevice.id,
      launchAfterInstall: true
    )
  }

  func installTargetDevice(
    id: String,
    sourceDevice: SimulatorDevice,
    in state: State
  ) -> SimulatorDevice? {
    installTargetCandidates(sourceDevice: sourceDevice, in: state)
      .first { $0.id == id }
  }

  func installTargetCandidates(
    sourceDevice: SimulatorDevice,
    in state: State
  ) -> [SimulatorDevice] {
    (state.workspace.snapshot?.devices ?? []).filter { target in
      target.id != sourceDevice.id
        && target.isAvailable
        && target.platform == sourceDevice.platform
        && (target.state == .booted || target.state == .shutdown)
    }
  }

  func canLaunchApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && (device.state == .booted || device.state == .shutdown)
  }

  func canTerminateApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && device.state == .booted
  }

  func canUninstallApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && (device.state == .booted || device.state == .shutdown)
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

  func nonEmpty(_ value: String) -> String? {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }

  func normalizedCoordinate(
    _ coordinate: DeveloperToolsFeature.LocationCoordinateInput
  ) -> DeveloperToolsFeature.LocationCoordinateInput? {
    guard let latitude = Double(
      DeveloperToolsFeature.State.trimmed(coordinate.latitude)
    ),
          let longitude = Double(
            DeveloperToolsFeature.State.trimmed(coordinate.longitude)
          )
    else {
      return nil
    }

    return DeveloperToolsFeature.LocationCoordinateInput(
      name: coordinate.name,
      latitude: Self.normalizedCoordinateValue(latitude),
      longitude: Self.normalizedCoordinateValue(longitude)
    )
  }

  static func normalizedCoordinateValue(_ value: Double) -> String {
    String(
      format: "%.6f",
      locale: Locale(identifier: "en_US_POSIX"),
      value
    )
  }
}
