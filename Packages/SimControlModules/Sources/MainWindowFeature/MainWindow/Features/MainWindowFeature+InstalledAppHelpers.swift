import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature Installed App Helpers

extension MainWindowFeature {
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
}
