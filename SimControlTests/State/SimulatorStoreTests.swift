import Foundation
import Testing
@testable import SimControl

@MainActor
@Suite
struct SimulatorStoreTests {
  @Test func successfulRefreshUpdatesSnapshotAndCommandResults() async throws {
    let snapshot = makeSnapshot(deviceIDs: ["DEVICE-1"])
    let xcodeCommandResult = makeCommandResult(id: "xcode", arguments: ["xcode-select", "-p"])
    let listCommandResult = makeCommandResult(id: "list", arguments: ["simctl", "list", "-j"])
    let store = SimulatorStore(
      refreshProvider: {
        makeRefreshResult(
          snapshot: snapshot,
          xcodeCommandResult: xcodeCommandResult,
          listCommandResult: listCommandResult
        )
      }
    )

    await store.refresh()

    #expect(store.snapshot == snapshot)
    #expect(store.refreshState == .idle)
    #expect(store.lastCommandResults == [xcodeCommandResult, listCommandResult])
  }

  @Test func failedRefreshPreservesLastSuccessfulSnapshot() async throws {
    let successfulSnapshot = makeSnapshot(deviceIDs: ["DEVICE-1"])
    let xcodeCommandResult = makeCommandResult(id: "xcode")
    let failedListCommandResult = makeCommandResult(id: "list-failed", exitCode: 65)
    let recorder = RefreshResultRecorder(
      results: [
        makeRefreshResult(snapshot: successfulSnapshot),
        makeRefreshResult(
          snapshot: nil,
          xcodeCommandResult: xcodeCommandResult,
          listCommandResult: failedListCommandResult,
          diagnostic: "Unable to load simulator inventory."
        )
      ]
    )
    let store = SimulatorStore {
      await recorder.nextResult()
    }

    await store.refresh()
    await store.refresh()

    #expect(store.snapshot == successfulSnapshot)
    #expect(store.refreshState == .failed(diagnostic: "Unable to load simulator inventory."))
    #expect(store.lastCommandResults == [xcodeCommandResult, failedListCommandResult])
  }

  @Test func concurrentRefreshRequestsUseOneProviderCall() async throws {
    let snapshot = makeSnapshot(deviceIDs: ["DEVICE-1"])
    let recorder = BlockingRefreshRecorder(
      result: makeRefreshResult(snapshot: snapshot)
    )
    let store = SimulatorStore {
      await recorder.refresh()
    }

    async let firstRefresh: Void = store.refresh()
    await recorder.waitUntilRefreshStarted()

    async let secondRefresh: Void = store.refresh()
    try? await Task.sleep(nanoseconds: 50_000_000)

    #expect(await recorder.refreshCallCount() == 1)
    await recorder.releaseRefresh()

    await firstRefresh
    await secondRefresh

    #expect(await recorder.refreshCallCount() == 1)
    #expect(store.snapshot == snapshot)
    #expect(store.refreshState == .idle)
  }

  @Test func successfulRefreshValidatesSelection() async throws {
    let recorder = RefreshResultRecorder(
      results: [
        makeRefreshResult(snapshot: makeSnapshot(deviceIDs: ["DEVICE-1", "DEVICE-2"])),
        makeRefreshResult(snapshot: makeSnapshot(deviceIDs: ["DEVICE-2"]))
      ]
    )
    let store = SimulatorStore {
      await recorder.nextResult()
    }

    await store.refresh()
    store.selectDevice(id: "DEVICE-1")
    store.selectApp(id: "DEVICE-1:com.example.app")

    #expect(store.selectedDeviceID == "DEVICE-1")
    #expect(store.selectedAppID == "DEVICE-1:com.example.app")

    await store.refresh()

    #expect(store.selectedDeviceID == nil)
    #expect(store.selectedAppID == nil)
  }

  @Test func selectingDifferentDeviceClearsSelectedApp() async throws {
    let store = SimulatorStore {
      makeRefreshResult(snapshot: makeSnapshot(deviceIDs: ["DEVICE-1", "DEVICE-2"]))
    }

    store.selectDevice(id: "DEVICE-1")
    store.selectApp(id: "DEVICE-1:com.example.app")
    store.selectDevice(id: "DEVICE-2")

    #expect(store.selectedDeviceID == "DEVICE-2")
    #expect(store.selectedAppID == nil)
  }

  @Test func emptyInstalledAppsRemainNotLoadedInPhaseEight() async throws {
    let snapshot = makeSnapshot(deviceIDs: ["DEVICE-1"], installedAppsByDeviceID: [:])
    let store = SimulatorStore {
      makeRefreshResult(snapshot: snapshot)
    }

    await store.refresh()

    #expect(store.snapshot?.installedAppsByDeviceID.isEmpty == true)
    #expect(store.installedAppsAvailability == .notLoaded)
  }

  @Test func loadedInstalledAppsClearStaleSelectedAppAfterRefresh() async throws {
    let app = makeInstalledApp(deviceID: "DEVICE-1", bundleID: "com.example.app")
    let recorder = RefreshResultRecorder(
      results: [
        makeRefreshResult(
          snapshot: makeSnapshot(
            deviceIDs: ["DEVICE-1"],
            installedAppsByDeviceID: ["DEVICE-1": [app]]
          )
        ),
        makeRefreshResult(
          snapshot: makeSnapshot(
            deviceIDs: ["DEVICE-1"],
            installedAppsByDeviceID: ["DEVICE-1": []]
          )
        )
      ]
    )
    let store = SimulatorStore(installedAppsAvailability: .loaded) {
      await recorder.nextResult()
    }

    await store.refresh()
    store.selectDevice(id: "DEVICE-1")
    store.selectApp(id: app.id)

    await store.refresh()

    #expect(store.selectedDeviceID == "DEVICE-1")
    #expect(store.selectedAppID == nil)
    #expect(store.installedAppsAvailability == .loaded)
  }

  @Test func notLoadedInstalledAppsDoNotClearSelectedAppFromEmptyDictionary() async throws {
    let snapshot = makeSnapshot(deviceIDs: ["DEVICE-1"], installedAppsByDeviceID: [:])
    let store = SimulatorStore {
      makeRefreshResult(snapshot: snapshot)
    }

    store.selectDevice(id: "DEVICE-1")
    store.selectApp(id: "DEVICE-1:com.example.app")

    await store.refresh()

    #expect(store.selectedDeviceID == "DEVICE-1")
    #expect(store.selectedAppID == "DEVICE-1:com.example.app")
    #expect(store.installedAppsAvailability == .notLoaded)
  }

  private func makeRefreshResult(
    snapshot: SimulatorSnapshot?,
    xcodeCommandResult: CommandResult = CommandResult(
      id: "xcode",
      executable: "xcrun",
      arguments: ["xcode-select", "-p"],
      stdout: "",
      stderr: "",
      exitCode: 0,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    ),
    listCommandResult: CommandResult? = CommandResult(
      id: "list",
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "",
      stderr: "",
      exitCode: 0,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    ),
    diagnostic: String? = nil
  ) -> SimulatorRepository.RefreshResult {
    SimulatorRepository.RefreshResult(
      snapshot: snapshot,
      xcodeCommandResult: xcodeCommandResult,
      listCommandResult: listCommandResult,
      diagnostic: diagnostic
    )
  }

  private func makeSnapshot(
    deviceIDs: [String],
    installedAppsByDeviceID: [String: [InstalledApp]] = [:]
  ) -> SimulatorSnapshot {
    let runtime = SimulatorRuntime(
      id: "runtime-ios",
      name: "iOS 26.4",
      version: "26.4",
      buildVersion: "23E244",
      platform: .iOS,
      isAvailable: true,
      supportedDeviceTypeIDs: ["device-type-iphone"]
    )
    let deviceType = SimulatorDeviceType(
      id: "device-type-iphone",
      name: "iPhone 17 Pro",
      productFamily: "iPhone",
      modelIdentifier: "iPhone18,1"
    )
    let devices = deviceIDs.map { deviceID in
      SimulatorDevice(
        id: deviceID,
        udid: deviceID,
        name: "Device \(deviceID)",
        runtimeID: runtime.id,
        deviceTypeID: deviceType.id,
        platform: .iOS,
        state: .shutdown,
        isAvailable: true,
        dataPath: URL(fileURLWithPath: "/tmp/\(deviceID)/data"),
        logPath: URL(fileURLWithPath: "/tmp/\(deviceID)/logs"),
        lastBootedAt: nil,
        dataPathSize: nil
      )
    }

    return SimulatorSnapshot(
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

  private func makeCommandResult(
    id: String,
    arguments: [String] = ["simctl", "list", "-j"],
    exitCode: Int32 = 0
  ) -> CommandResult {
    CommandResult(
      id: id,
      executable: "xcrun",
      arguments: arguments,
      stdout: "",
      stderr: "",
      exitCode: exitCode,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    )
  }

  private func makeInstalledApp(deviceID: String, bundleID: String) -> InstalledApp {
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
}

private actor RefreshResultRecorder {
  private var results: [SimulatorRepository.RefreshResult]

  init(results: [SimulatorRepository.RefreshResult]) {
    self.results = results
  }

  func nextResult() -> SimulatorRepository.RefreshResult {
    guard results.count > 1 else {
      return results[0]
    }

    return results.removeFirst()
  }
}

private actor BlockingRefreshRecorder {
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
