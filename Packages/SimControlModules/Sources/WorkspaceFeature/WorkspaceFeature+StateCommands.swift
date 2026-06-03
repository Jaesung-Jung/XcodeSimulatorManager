import MainWindowFeatureSupport

// MARK: - WorkspaceFeature.State Commands

extension WorkspaceFeature.State {
  public mutating func setDeviceCommandState(_ deviceCommandState: DeviceCommandState?) {
    self.deviceCommandState = deviceCommandState
    deviceDetail.deviceCommandState = deviceCommandState
    deviceDetail.installedApps.isDeviceCommandRunning = deviceCommandState != nil
    deviceDetail.developerTools.deviceCommandState = deviceCommandState
  }

  public mutating func setAppCommandState(_ appCommandState: AppCommandState?) {
    self.appCommandState = appCommandState
    deviceDetail.appCommandState = appCommandState
    deviceDetail.installedApps.appCommandState = appCommandState
    deviceDetail.developerTools.appCommandState = appCommandState
  }

  public mutating func setOpeningSimulatorApp(_ isOpeningSimulatorApp: Bool) {
    self.isOpeningSimulatorApp = isOpeningSimulatorApp
    deviceDetail.isOpeningSimulatorApp = isOpeningSimulatorApp
  }
}
