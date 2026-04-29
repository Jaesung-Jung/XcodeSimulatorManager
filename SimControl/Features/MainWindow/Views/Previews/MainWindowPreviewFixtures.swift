import Foundation

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
      $0.coreSimulatorService.shutdownDevice = { _ in
        MainWindowPreviewFixtures.commandResults[1]
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
