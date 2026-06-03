import Foundation
import SimControlDomain

#if DEBUG
import ComposableArchitecture

extension MainWindowFeature.State {
  static var preview: MainWindowFeature.State {
    MainWindowFeature.State(
      snapshot: MainWindowPreviewFixtures.snapshot,
      refreshState: .idle,
      selectedDeviceID: MainWindowPreviewFixtures.device.id,
      selectedAppID: nil,
      lastCommandResults: MainWindowPreviewFixtures.commandResults,
      installedAppsAvailability: .notLoaded
    )
  }
}

extension Store where State == MainWindowFeature.State, Action == MainWindowFeature.Action {
  @MainActor
  static var mainWindowPreview: StoreOf<MainWindowFeature> {
    Store(initialState: .preview) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        MainWindowPreviewFixtures.refreshResult
      }
      $0.coreSimulatorService.openSimulatorApp = {
        MainWindowPreviewFixtures.openSimulatorCommandResult
      }
      $0.coreSimulatorService.bootDevice = { _ in
        MainWindowPreviewFixtures.commandResults[1]
      }
      $0.coreSimulatorService.bootDeviceIfNeeded = { _ in
        MainWindowPreviewFixtures.bootStatusCommandResult
      }
      $0.coreSimulatorService.shutdownDevice = { _ in
        MainWindowPreviewFixtures.commandResults[1]
      }
      $0.coreSimulatorService.createDevice = { _, _, _ in
        MainWindowPreviewFixtures.createDeviceCommandResult
      }
      $0.coreSimulatorService.cloneDevice = { _, _ in
        MainWindowPreviewFixtures.cloneDeviceCommandResult
      }
      $0.coreSimulatorService.renameDevice = { _, _ in
        MainWindowPreviewFixtures.renameDeviceCommandResult
      }
      $0.coreSimulatorService.eraseDevice = { _ in
        MainWindowPreviewFixtures.eraseDeviceCommandResult
      }
      $0.coreSimulatorService.deleteDevice = { _ in
        MainWindowPreviewFixtures.deleteDeviceCommandResult
      }
      $0.coreSimulatorService.pairDevices = { _, _ in
        MainWindowPreviewFixtures.pairDevicesCommandResult
      }
      $0.coreSimulatorService.unpairDevice = { _ in
        MainWindowPreviewFixtures.unpairDeviceCommandResult
      }
      $0.coreSimulatorService.launchApp = { _, _ in
        MainWindowPreviewFixtures.launchAppCommandResult
      }
      $0.coreSimulatorService.terminateApp = { _, _ in
        MainWindowPreviewFixtures.terminateAppCommandResult
      }
      $0.coreSimulatorService.uninstallApp = { _, _ in
        MainWindowPreviewFixtures.uninstallAppCommandResult
      }
      $0.coreSimulatorService.installApp = { _, _ in
        MainWindowPreviewFixtures.installAppCommandResult
      }
      $0.appSandboxReset.resetSandbox = { _ in
        MainWindowPreviewFixtures.resetSandboxCommandResult
      }
    }
  }
}

enum MainWindowPreviewFixtures {
  static let runtime = SimulatorRuntime(
    id: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: ["com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"]
  )

  static let deviceType = SimulatorDeviceType(
    id: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    name: "iPhone 17 Pro",
    productFamily: "iPhone",
    modelIdentifier: "iPhone18,1"
  )

  static let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "PREVIEW-DEVICE-1",
    name: "iPhone 17 Pro",
    runtimeID: runtime.id,
    deviceTypeID: deviceType.id,
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: URL(fileURLWithPath: "/Users/example/Library/Developer/CoreSimulator/Devices/PREVIEW-DEVICE-1/data"),
    logPath: URL(fileURLWithPath: "/Users/example/Library/Logs/CoreSimulator/PREVIEW-DEVICE-1"),
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )

  static let app = InstalledApp(
    id: "PREVIEW-DEVICE-1:com.example.preview",
    bundleID: "com.example.preview",
    displayName: "Preview App",
    version: "1.0",
    build: "100",
    deviceID: device.id,
    bundleContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle"),
    dataContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Data"),
    appBundlePath: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle/Preview.app"),
    appGroups: [
      AppGroupContainer(
        id: "group.com.example.preview",
        groupID: "group.com.example.preview",
        path: URL(fileURLWithPath: "/tmp/PreviewApp/Groups/group.com.example.preview")
      )
    ],
    iconPath: nil
  )

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

  static let snapshot = SimulatorSnapshot(
    generatedAt: Date(timeIntervalSince1970: 1_020),
    xcode: XcodeSelection(
      developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
      version: nil,
      isValid: true
    ),
    runtimes: [runtime],
    deviceTypes: [deviceType],
    devices: [device],
    pairs: [],
    installedAppsByDeviceID: [device.id: [app]],
    warnings: [
      SimulatorWarning(
        id: "preview-warning",
        severity: .warning,
        category: .device,
        message: "Preview warning for simulator inventory.",
        relatedID: device.id
      )
    ]
  )

  static var refreshResult: SimulatorRepository.RefreshResult {
    SimulatorRepository.RefreshResult(
      snapshot: snapshot,
      xcodeCommandResult: CommandResult(
        id: "preview-xcode",
        executable: "xcode-select",
        arguments: ["-p"],
        stdout: "/Applications/Xcode.app/Contents/Developer\n",
        stderr: "",
        exitCode: 0,
        duration: 0.04,
        startedAt: Date(timeIntervalSince1970: 1_000)
      ),
      listCommandResult: commandResults[0],
      diagnostic: nil
    )
  }
}
#endif
