import Foundation
import SwiftUI

#if DEBUG

#Preview("Create Simulator Sheet") {
  CreateDeviceView(
    formState: MainWindowFeature.CreateDeviceFormState(),
    runtimes: [MainWindowPreviewFixtures.runtime],
    deviceTypes: [MainWindowPreviewFixtures.deviceType]
  ) { _ in }
}

#Preview("Install App Sheet") {
  InstallAppOnSimulatorView(
    formState: MainWindowFeature.InstallAppTargetFormState(
      sourceAppID: MainWindowPreviewFixtures.app.id,
      sourceDeviceID: MainWindowPreviewFixtures.device.id,
      appName: MainWindowPreviewFixtures.app.displayName,
      bundleID: MainWindowPreviewFixtures.app.bundleID,
      appBundlePath: MainWindowPreviewFixtures.app.appBundlePath ?? URL(fileURLWithPath: "/tmp/Preview.app"),
      targetDeviceID: MainWindowPreviewFixtures.device.id,
      launchAfterInstall: true
    ),
    targetCandidates: [
      MainWindowFeature.InstallAppTargetCandidate(device: MainWindowPreviewFixtures.device)
    ]
  ) { _ in }
}

#Preview("Erase Simulator Confirmation") {
  DeviceDestructiveConfirmationView(
    titleKey: "main_window.erase.title",
    messageKey: "main_window.erase.message",
    actionTitleKey: "main_window.erase.action",
    systemImage: "eraser",
    confirmationState: MainWindowFeature.DeviceDestructiveConfirmationState(
      deviceID: MainWindowPreviewFixtures.device.id,
      deviceName: MainWindowPreviewFixtures.device.name,
      deviceUDID: MainWindowPreviewFixtures.device.udid
    )
  ) { _ in }
}

#Preview("Reset Sandbox Confirmation") {
  AppDestructiveConfirmationView(
    titleKey: "main_window.reset_sandbox.title",
    messageKey: "main_window.reset_sandbox.message",
    actionTitleKey: "main_window.reset_sandbox.action",
    systemImage: "folder.badge.minus",
    confirmationState: MainWindowFeature.AppDestructiveConfirmationState(
      appID: MainWindowPreviewFixtures.app.id,
      appName: MainWindowPreviewFixtures.app.displayName,
      bundleID: MainWindowPreviewFixtures.app.bundleID,
      deviceID: MainWindowPreviewFixtures.device.id,
      deviceName: MainWindowPreviewFixtures.device.name,
      deviceUDID: MainWindowPreviewFixtures.device.udid,
      dataContainerPath: MainWindowPreviewFixtures.app.dataContainer?.path
    )
  ) { _ in }
}

#endif
