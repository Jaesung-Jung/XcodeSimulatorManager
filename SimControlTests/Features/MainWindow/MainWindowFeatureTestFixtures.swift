import Foundation

@testable import SimControl

enum MainWindowTestFixtures {
  static let runtime = SimulatorRuntime(
    id: "runtime-ios",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: ["device-type-iphone"]
  )

  static let deviceType = SimulatorDeviceType(
    id: "device-type-iphone",
    name: "iPhone 17 Pro",
    productFamily: "iPhone",
    modelIdentifier: "iPhone18,1"
  )

  static let device = makeDevice(id: "DEVICE-1")
  static let secondDevice = makeDevice(id: "DEVICE-2")

  static let app = makeInstalledApp(
    deviceID: device.id,
    bundleID: "com.example.app"
  )

  static let secondApp = makeInstalledApp(
    deviceID: secondDevice.id,
    bundleID: "com.example.second"
  )

  static let xcodeCommandResult = makeCommandResult(
    id: "xcode",
    executable: "xcode-select",
    arguments: ["-p"]
  )

  static let listCommandResult = makeCommandResult(
    id: "list",
    arguments: ["simctl", "list", "-j"]
  )

  static let failedXcodeCommandResult = makeCommandResult(
    id: "failed-xcode",
    executable: "xcode-select",
    arguments: ["-p"],
    exitCode: 1
  )

  static func makeRefreshResult(
    snapshot: SimulatorSnapshot?,
    xcodeCommandResult: CommandResult = xcodeCommandResult,
    listCommandResult: CommandResult? = listCommandResult,
    diagnostic: String? = nil
  ) -> SimulatorRepository.RefreshResult {
    SimulatorRepository.RefreshResult(
      snapshot: snapshot,
      xcodeCommandResult: xcodeCommandResult,
      listCommandResult: listCommandResult,
      diagnostic: diagnostic
    )
  }

  static func makeSnapshot(
    devices: [SimulatorDevice] = [device],
    installedAppsByDeviceID: [String: [InstalledApp]] = [:]
  ) -> SimulatorSnapshot {
    SimulatorSnapshot(
      generatedAt: Date(timeIntervalSince1970: 1_000),
      xcode: XcodeSelection(
        developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
        version: nil,
        isValid: true
      ),
      runtimes: [runtime],
      deviceTypes: [deviceType],
      devices: devices,
      pairs: [],
      installedAppsByDeviceID: installedAppsByDeviceID,
      warnings: []
    )
  }

  static func makeDevice(id: String) -> SimulatorDevice {
    SimulatorDevice(
      id: id,
      udid: id,
      name: "Device \(id)",
      runtimeID: runtime.id,
      deviceTypeID: deviceType.id,
      platform: .iOS,
      state: .shutdown,
      isAvailable: true,
      dataPath: URL(fileURLWithPath: "/tmp/\(id)/data"),
      logPath: URL(fileURLWithPath: "/tmp/\(id)/logs"),
      lastBootedAt: nil,
      dataPathSize: nil
    )
  }

  static func makeInstalledApp(deviceID: String, bundleID: String) -> InstalledApp {
    InstalledApp(
      id: "\(deviceID):\(bundleID)",
      bundleID: bundleID,
      displayName: "Example",
      version: "1.0",
      build: "100",
      deviceID: deviceID,
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil
    )
  }

  static func makeCommandResult(
    id: String,
    executable: String = "xcrun",
    arguments: [String] = ["simctl", "list", "-j"],
    exitCode: Int32 = 0
  ) -> CommandResult {
    CommandResult(
      id: id,
      executable: executable,
      arguments: arguments,
      stdout: "",
      stderr: exitCode == 0 ? "" : "simctl list failed",
      exitCode: exitCode,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    )
  }
}

actor MainWindowBlockingRefreshRecorder {
  private let result: SimulatorRepository.RefreshResult
  private var refreshCalls = 0
  private var startedWaiters: [CheckedContinuation<Void, Never>] = []
  private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
  private var refreshReleased = false

  init(result: SimulatorRepository.RefreshResult) {
    self.result = result
  }

  func refresh() async -> SimulatorRepository.RefreshResult {
    refreshCalls += 1
    resumeStartedWaiters()

    if !refreshReleased {
      await withCheckedContinuation { continuation in
        releaseContinuations.append(continuation)
      }
    }

    return result
  }

  func waitUntilRefreshStarted() async {
    guard refreshCalls == 0 else {
      return
    }

    await withCheckedContinuation { continuation in
      startedWaiters.append(continuation)
    }
  }

  func releaseRefresh() {
    refreshReleased = true
    let continuations = releaseContinuations
    releaseContinuations.removeAll()
    continuations.forEach { $0.resume() }
  }

  func refreshCallCount() -> Int {
    refreshCalls
  }

  private func resumeStartedWaiters() {
    let waiters = startedWaiters
    startedWaiters.removeAll()
    waiters.forEach { $0.resume() }
  }
}
