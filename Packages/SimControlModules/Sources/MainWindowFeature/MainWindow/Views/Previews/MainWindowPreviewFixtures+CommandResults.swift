import Foundation
import SimControlDomain

#if DEBUG

extension MainWindowPreviewFixtures {
  static let commandResults = [
    CommandResult(
      id: "preview-list",
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "",
      stderr: "",
      exitCode: 0,
      duration: 0.18,
      startedAt: Date(timeIntervalSince1970: 1_001)
    ),
    CommandResult(
      id: "preview-failed",
      executable: "xcrun",
      arguments: ["simctl", "boot", device.id],
      stdout: "",
      stderr: "Unable to boot device in preview.",
      exitCode: 65,
      duration: 0.42,
      startedAt: Date(timeIntervalSince1970: 1_002)
    )
  ]

  static let openSimulatorCommandResult = CommandResult(
    id: "preview-open-simulator",
    executable: "open",
    arguments: ["-a", "Simulator"],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.06,
    startedAt: Date(timeIntervalSince1970: 1_003)
  )

  static let createDeviceCommandResult = CommandResult(
    id: "preview-create-device",
    executable: "xcrun",
    arguments: [
      "simctl",
      "create",
      "iPhone 17 Pro",
      deviceType.id,
      runtime.id
    ],
    stdout: "PREVIEW-DEVICE-CREATED\n",
    stderr: "",
    exitCode: 0,
    duration: 0.2,
    startedAt: Date(timeIntervalSince1970: 1_004)
  )

  static let cloneDeviceCommandResult = CommandResult(
    id: "preview-clone-device",
    executable: "xcrun",
    arguments: ["simctl", "clone", device.id, "iPhone 17 Pro Copy"],
    stdout: "PREVIEW-DEVICE-CLONED\n",
    stderr: "",
    exitCode: 0,
    duration: 0.2,
    startedAt: Date(timeIntervalSince1970: 1_005)
  )

  static let renameDeviceCommandResult = CommandResult(
    id: "preview-rename-device",
    executable: "xcrun",
    arguments: ["simctl", "rename", device.id, "Renamed Simulator"],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.1,
    startedAt: Date(timeIntervalSince1970: 1_006)
  )

  static let eraseDeviceCommandResult = CommandResult(
    id: "preview-erase-device",
    executable: "xcrun",
    arguments: ["simctl", "erase", device.id],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.4,
    startedAt: Date(timeIntervalSince1970: 1_007)
  )

  static let deleteDeviceCommandResult = CommandResult(
    id: "preview-delete-device",
    executable: "xcrun",
    arguments: ["simctl", "delete", device.id],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.3,
    startedAt: Date(timeIntervalSince1970: 1_008)
  )

  static let pairDevicesCommandResult = CommandResult(
    id: "preview-pair-devices",
    executable: "xcrun",
    arguments: ["simctl", "pair", "PREVIEW-WATCH-1", device.id],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0.2,
    startedAt: Date(timeIntervalSince1970: 1_009)
  )
}

#endif
