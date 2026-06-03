import Foundation
import SimControlClients
import SimControlDomain
import SimControlInfrastructure

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

  static let watchRuntime = SimulatorRuntime(
    id: "runtime-watchos",
    name: "watchOS 26.4",
    version: "26.4",
    buildVersion: "23T244",
    platform: .watchOS,
    isAvailable: true,
    supportedDeviceTypeIDs: ["device-type-watch"]
  )

  static let watchDeviceType = SimulatorDeviceType(
    id: "device-type-watch",
    name: "Apple Watch Series 11",
    productFamily: "Apple Watch",
    modelIdentifier: "Watch7,1"
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
    generatedAt: Date = Date(timeIntervalSince1970: 1_000),
    runtimes: [SimulatorRuntime] = [runtime],
    deviceTypes: [SimulatorDeviceType] = [deviceType],
    devices: [SimulatorDevice] = [device],
    pairs: [DevicePair] = [],
    installedAppsByDeviceID: [String: [InstalledApp]] = [:],
    warnings: [SimulatorWarning] = []
  ) -> SimulatorSnapshot {
    SimulatorSnapshot(
      generatedAt: generatedAt,
      xcode: XcodeSelection(
        developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
        version: nil,
        isValid: true
      ),
      runtimes: runtimes,
      deviceTypes: deviceTypes,
      devices: devices,
      pairs: pairs,
      installedAppsByDeviceID: installedAppsByDeviceID,
      warnings: warnings
    )
  }

  static func makeDevice(
    id: String,
    name: String? = nil,
    state: SimulatorDevice.State = .shutdown,
    isAvailable: Bool = true,
    runtimeID: String = runtime.id,
    deviceTypeID: String = deviceType.id,
    platform: SimulatorPlatform = .iOS
  ) -> SimulatorDevice {
    SimulatorDevice(
      id: id,
      udid: id,
      name: name ?? "Device \(id)",
      runtimeID: runtimeID,
      deviceTypeID: deviceTypeID,
      platform: platform,
      state: state,
      isAvailable: isAvailable,
      dataPath: URL(fileURLWithPath: "/tmp/\(id)/data"),
      logPath: URL(fileURLWithPath: "/tmp/\(id)/logs"),
      lastBootedAt: nil,
      dataPathSize: nil
    )
  }

  static func makeInstalledApp(
    deviceID: String,
    bundleID: String,
    bundleContainer: URL? = nil,
    dataContainer: URL? = nil,
    appBundlePath: URL? = nil,
    appGroups: [AppGroupContainer] = [],
    isSystemApp: Bool = false,
    databaseFiles: [URL] = [],
    dataContainerSize: Int64? = nil
  ) -> InstalledApp {
    InstalledApp(
      id: "\(deviceID):\(bundleID)",
      bundleID: bundleID,
      displayName: "Example",
      version: "1.0",
      build: "100",
      deviceID: deviceID,
      bundleContainer: bundleContainer,
      dataContainer: dataContainer,
      appBundlePath: appBundlePath,
      appGroups: appGroups,
      iconPath: nil,
      isSystemApp: isSystemApp,
      databaseFiles: databaseFiles,
      dataContainerSize: dataContainerSize
    )
  }

  static func makeCommandResult(
    id: String,
    executable: String = "xcrun",
    arguments: [String] = ["simctl", "list", "-j"],
    stdout: String = "",
    stderr: String? = nil,
    exitCode: Int32 = 0
  ) -> CommandResult {
    CommandResult(
      id: id,
      executable: executable,
      arguments: arguments,
      stdout: stdout,
      stderr: stderr ?? (exitCode == 0 ? "" : "simctl list failed"),
      exitCode: exitCode,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    )
  }
}

actor MainWindowRefreshRecorder {
  private let result: SimulatorRepository.RefreshResult
  private var refreshCalls = 0

  init(result: SimulatorRepository.RefreshResult) {
    self.result = result
  }

  func refresh() -> SimulatorRepository.RefreshResult {
    refreshCalls += 1
    return result
  }

  func refreshCallCount() -> Int {
    refreshCalls
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

actor MainWindowCommandRecorder {
  private let result: CommandResult
  private var callCount = 0

  init(result: CommandResult) {
    self.result = result
  }

  func run() -> CommandResult {
    callCount += 1
    return result
  }

  func calls() -> Int {
    callCount
  }
}

actor MainWindowBlockingCommandRecorder {
  private let result: CommandResult
  private var callCount = 0
  private var startedWaiters: [CheckedContinuation<Void, Never>] = []
  private var releaseContinuations: [CheckedContinuation<Void, Never>] = []
  private var commandReleased = false

  init(result: CommandResult) {
    self.result = result
  }

  func run() async -> CommandResult {
    callCount += 1
    resumeStartedWaiters()

    if !commandReleased {
      await withCheckedContinuation { continuation in
        releaseContinuations.append(continuation)
      }
    }

    return result
  }

  func waitUntilCommandStarted() async {
    guard callCount == 0 else {
      return
    }

    await withCheckedContinuation { continuation in
      startedWaiters.append(continuation)
    }
  }

  func releaseCommand() {
    commandReleased = true
    let continuations = releaseContinuations
    releaseContinuations.removeAll()
    continuations.forEach { $0.resume() }
  }

  func calls() -> Int {
    callCount
  }

  private func resumeStartedWaiters() {
    let waiters = startedWaiters
    startedWaiters.removeAll()
    waiters.forEach { $0.resume() }
  }
}
