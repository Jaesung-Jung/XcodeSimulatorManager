import Foundation
import SimControlDomain

#if DEBUG

extension MainWindowPreviewFixtures {
  static let unpairDeviceCommandResult = CommandResult(
    id: "preview-unpair-device",
    executable: "xcrun",
    arguments: ["simctl", "unpair", "PREVIEW-PAIR-1"],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.2,
    startedAt: Date(timeIntervalSince1970: 1_010)
  )

  static let bootStatusCommandResult = CommandResult(
    id: "preview-bootstatus",
    executable: "xcrun",
    arguments: ["simctl", "bootstatus", device.id, "-b"],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.8,
    startedAt: Date(timeIntervalSince1970: 1_011)
  )

  static let launchAppCommandResult = CommandResult(
    id: "preview-launch-app",
    executable: "xcrun",
    arguments: ["simctl", "launch", device.id, app.bundleID],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.2,
    startedAt: Date(timeIntervalSince1970: 1_012)
  )

  static let terminateAppCommandResult = CommandResult(
    id: "preview-terminate-app",
    executable: "xcrun",
    arguments: ["simctl", "terminate", device.id, app.bundleID],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.1,
    startedAt: Date(timeIntervalSince1970: 1_013)
  )

  static let uninstallAppCommandResult = CommandResult(
    id: "preview-uninstall-app",
    executable: "xcrun",
    arguments: ["simctl", "uninstall", device.id, app.bundleID],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.3,
    startedAt: Date(timeIntervalSince1970: 1_014)
  )

  static let installAppCommandResult = CommandResult(
    id: "preview-install-app",
    executable: "xcrun",
    arguments: ["simctl", "install", "PREVIEW-DEVICE-2", app.appBundlePath?.path ?? ""],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.5,
    startedAt: Date(timeIntervalSince1970: 1_015)
  )

  static let resetSandboxCommandResult = CommandResult(
    id: "preview-reset-sandbox",
    executable: "SimControl",
    arguments: ["reset-sandbox", app.dataContainer?.path ?? ""],
    stdout: "Removed 3 sandbox item(s).",
    stderr: "",
    exitCode: 0,
    duration: 0.1,
    startedAt: Date(timeIntervalSince1970: 1_016)
  )
}

#endif
