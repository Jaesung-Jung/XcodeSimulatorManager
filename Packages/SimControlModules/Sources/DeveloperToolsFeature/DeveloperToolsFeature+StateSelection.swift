import MainWindowFeatureSupport
import SimControlDomain

// MARK: - DeveloperToolsFeature.State Selection

extension DeveloperToolsFeature.State {
  public var selectedApp: InstalledApp? {
    guard let selectedAppID else {
      return nil
    }

    return installedApps.first { $0.id == selectedAppID }
  }

  public var selectedAppBundleID: String? {
    selectedApp?.bundleID
  }

  public var appBundleIDOptions: [String] {
    Array(Set(installedApps.map(\.bundleID).filter { !$0.isEmpty }))
      .sorted()
  }

  public mutating func updateContext(
    device: SimulatorDevice?,
    installedApps: [InstalledApp],
    selectedAppID: String?,
    deviceCommandState: DeviceCommandState?,
    appCommandState: AppCommandState?
  ) {
    let previousDeviceID = self.device?.id
    self.device = device
    self.installedApps = installedApps
    self.selectedAppID = selectedAppID
    self.deviceCommandState = deviceCommandState
    self.appCommandState = appCommandState

    if previousDeviceID != device?.id {
      pushBundleID = selectedApp?.bundleID ?? ""
      privacyBundleID = selectedApp?.bundleID ?? ""
    } else {
      applySelectedAppBundleIfNeeded()
    }
  }

  public mutating func applySelectedAppBundle() {
    guard let selectedAppBundleID else {
      return
    }

    pushBundleID = selectedAppBundleID
    privacyBundleID = selectedAppBundleID
  }
}
