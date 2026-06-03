import Foundation
import SwiftUI

#if DEBUG

#Preview("Create Simulator Sheet") {
  CreateDeviceView(
    formState: CreateDeviceFormState(),
    runtimes: [MainWindowSheetPreviewFixtures.runtime],
    deviceTypes: [MainWindowSheetPreviewFixtures.deviceType]
  ) { _ in }
}

#Preview("Install App Sheet") {
  InstallAppOnSimulatorView(
    formState: InstallAppTargetFormState(
      sourceAppID: MainWindowSheetPreviewFixtures.app.id,
      sourceDeviceID: MainWindowSheetPreviewFixtures.device.id,
      appName: MainWindowSheetPreviewFixtures.app.displayName,
      bundleID: MainWindowSheetPreviewFixtures.app.bundleID,
      appBundlePath: MainWindowSheetPreviewFixtures.app.appBundlePath ?? URL(fileURLWithPath: "/tmp/Preview.app"),
      targetDeviceID: MainWindowSheetPreviewFixtures.device.id,
      launchAfterInstall: true
    ),
    targetCandidates: [
      InstallAppTargetCandidate(device: MainWindowSheetPreviewFixtures.device)
    ]
  ) { _ in }
}

#Preview("Erase Simulator Confirmation") {
  DeviceDestructiveConfirmationView(
    titleKey: "main_window.erase.title",
    messageKey: "main_window.erase.message",
    actionTitleKey: "main_window.erase.action",
    systemImage: "eraser",
    confirmationState: DeviceDestructiveConfirmationState(
      deviceID: MainWindowSheetPreviewFixtures.device.id,
      deviceName: MainWindowSheetPreviewFixtures.device.name,
      deviceUDID: MainWindowSheetPreviewFixtures.device.udid
    )
  ) { _ in }
}

#Preview("Reset Sandbox Confirmation") {
  AppDestructiveConfirmationView(
    titleKey: "main_window.reset_sandbox.title",
    messageKey: "main_window.reset_sandbox.message",
    actionTitleKey: "main_window.reset_sandbox.action",
    systemImage: "folder.badge.minus",
    confirmationState: AppDestructiveConfirmationState(
      appID: MainWindowSheetPreviewFixtures.app.id,
      appName: MainWindowSheetPreviewFixtures.app.displayName,
      bundleID: MainWindowSheetPreviewFixtures.app.bundleID,
      deviceID: MainWindowSheetPreviewFixtures.device.id,
      deviceName: MainWindowSheetPreviewFixtures.device.name,
      deviceUDID: MainWindowSheetPreviewFixtures.device.udid,
      dataContainerPath: MainWindowSheetPreviewFixtures.app.dataContainer?.path
    )
  ) { _ in }
}

#endif
