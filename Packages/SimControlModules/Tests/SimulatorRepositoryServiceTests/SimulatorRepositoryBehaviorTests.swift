import AppContainerScanningService
import CoreSimulatorService
import Foundation
import SimControlDomain
import Testing
@testable import SimulatorRepositoryService

@Suite
struct SimulatorRepositoryTests {
  @Test func refreshMapsServicePayloadIntoDomainSnapshot() async throws {
    let generatedAt = Date(timeIntervalSince1970: 1_000)
    let xcodeCommandResult = makeCommandResult(
      executable: "xcode-select",
      arguments: ["-p"],
      stdout: "/Applications/Xcode.app/Contents/Developer\n"
    )
    let listCommandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"]
    )
    let recorder = try RepositoryServiceRecorder(
      selectedXcodePathResult: makeSelectedXcodePathResult(commandResult: xcodeCommandResult),
      listResult: makeListResult(
        commandResult: listCommandResult,
        json: """
        {
          "runtimes": [
            {
              "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
              "name": "iOS 26.4",
              "version": "26.4",
              "buildversion": "23E244",
              "platform": "iOS",
              "isAvailable": true,
              "supportedDeviceTypes": [
                {
                  "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"
                }
              ]
            },
            {
              "identifier": "com.apple.CoreSimulator.SimRuntime.watchOS-26-4",
              "name": "watchOS 26.4",
              "version": "26.4",
              "buildversion": "23T200",
              "platform": "watchOS",
              "isAvailable": true,
              "supportedDeviceTypes": [
                {
                  "identifier": "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-10"
                }
              ]
            }
          ],
          "devicetypes": [
            {
              "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
              "name": "iPhone 17 Pro",
              "productFamily": "iPhone",
              "modelIdentifier": "iPhone18,1"
            }
          ],
          "devices": {
            "com.apple.CoreSimulator.SimRuntime.iOS-26-4": [
              {
                "udid": "PHONE-UDID",
                "name": "iPhone 17 Pro",
                "state": "Booted",
                "isAvailable": true,
                "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
                "dataPath": "/tmp/CoreSimulator/Devices/PHONE-UDID/data",
                "logPath": "/tmp/CoreSimulator/Devices/PHONE-UDID/logs",
                "lastBootedAt": "1970-01-01T00:05:00Z",
                "dataPathSize": 1024
              }
            ],
            "com.apple.CoreSimulator.SimRuntime.watchOS-26-4": [
              {
                "udid": "WATCH-UDID",
                "name": "Apple Watch Series 10",
                "state": "Shutdown",
                "isAvailable": true,
                "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.Apple-Watch-Series-10"
              }
            ]
          },
          "pairs": {
            "PAIR-1": {
              "state": "active",
              "phone": {
                "udid": "PHONE-UDID"
              },
              "watch": {
                "udid": "WATCH-UDID"
              }
            }
          }
        }
        """
      )
    )
    let repository = makeRepository(recorder: recorder, now: { generatedAt })

    let result = await repository.refresh()

    #expect(result.succeeded)
    #expect(result.diagnostic == nil)
    #expect(result.xcodeCommandResult == xcodeCommandResult)
    #expect(result.listCommandResult == listCommandResult)

    let snapshot = try #require(result.snapshot)
    #expect(snapshot.generatedAt == generatedAt)
    #expect(snapshot.xcode.developerPath == URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"))
    #expect(snapshot.xcode.version == nil)
    #expect(snapshot.xcode.isValid)
    #expect(snapshot.installedAppsByDeviceID.isEmpty)
    #expect(snapshot.warnings.isEmpty)

    let runtime = try #require(snapshot.runtimes.first { $0.id == "com.apple.CoreSimulator.SimRuntime.iOS-26-4" })
    #expect(runtime.name == "iOS 26.4")
    #expect(runtime.version == "26.4")
    #expect(runtime.buildVersion == "23E244")
    #expect(runtime.platform == .iOS)
    #expect(runtime.isAvailable)
    #expect(runtime.supportedDeviceTypeIDs == ["com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"])

    let deviceType = try #require(snapshot.deviceTypes.first)
    #expect(deviceType.id == "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro")
    #expect(deviceType.name == "iPhone 17 Pro")
    #expect(deviceType.productFamily == "iPhone")
    #expect(deviceType.modelIdentifier == "iPhone18,1")

    let phone = try #require(snapshot.devices.first { $0.id == "PHONE-UDID" })
    #expect(phone.udid == "PHONE-UDID")
    #expect(phone.runtimeID == "com.apple.CoreSimulator.SimRuntime.iOS-26-4")
    #expect(phone.platform == .iOS)
    #expect(phone.state == .booted)
    #expect(phone.dataPath == URL(fileURLWithPath: "/tmp/CoreSimulator/Devices/PHONE-UDID/data"))
    #expect(phone.logPath == URL(fileURLWithPath: "/tmp/CoreSimulator/Devices/PHONE-UDID/logs"))
    #expect(phone.lastBootedAt == Date(timeIntervalSince1970: 300))
    #expect(phone.dataPathSize == 1_024)

    let pair = try #require(snapshot.pairs.first)
    #expect(pair.id == "PAIR-1")
    #expect(pair.phoneDeviceID == "PHONE-UDID")
    #expect(pair.watchDeviceID == "WATCH-UDID")
    #expect(pair.state == .active)
    #expect(await recorder.selectedXcodePathCallCount() == 1)
    #expect(await recorder.listCallCount() == 1)
  }

  @Test func refreshStopsWhenXcodePathLookupFailsAndPreservesFailure() async throws {
    let xcodeCommandResult = makeCommandResult(
      executable: "xcode-select",
      arguments: ["-p"],
      stderr: "unable to get active developer directory",
      exitCode: 72
    )
    let diagnostic = "xcode-select -p failed with exit code 72."
    let recorder = try RepositoryServiceRecorder(
      selectedXcodePathResult: CoreSimulatorService.DeveloperPathResult(
        developerPath: nil,
        commandResult: xcodeCommandResult,
        diagnostic: diagnostic
      ),
      listResult: makeListResult(commandResult: makeCommandResult(), json: "{}")
    )
    let repository = makeRepository(recorder: recorder)

    let result = await repository.refresh()

    #expect(!result.succeeded)
    #expect(result.snapshot == nil)
    #expect(result.xcodeCommandResult == xcodeCommandResult)
    #expect(result.listCommandResult == nil)
    #expect(result.diagnostic == diagnostic)
    #expect(await recorder.selectedXcodePathCallCount() == 1)
    #expect(await recorder.listCallCount() == 0)
  }

  @Test func refreshIncludesScannerDiscoveredAppsAndWarnings() async throws {
    let app = InstalledApp(
      id: "PHONE-UDID:com.example.app",
      bundleID: "com.example.app",
      displayName: "Example",
      version: "1.0",
      build: "100",
      deviceID: "PHONE-UDID",
      bundleContainer: URL(fileURLWithPath: "/tmp/Bundle/Application/app"),
      dataContainer: URL(fileURLWithPath: "/tmp/Data/Application/app"),
      appBundlePath: URL(fileURLWithPath: "/tmp/Bundle/Application/app/App.app"),
      appGroups: [
        AppGroupContainer(
          id: "PHONE-UDID:group.com.example.shared",
          groupID: "group.com.example.shared",
          path: URL(fileURLWithPath: "/tmp/Shared/AppGroup/group")
        )
      ],
      iconPath: nil
    )
    let scannerWarning = SimulatorWarning(
      id: "apps-PHONE-UDID-fixture-warning",
      severity: .warning,
      category: .filesystem,
      message: "Fixture scanner warning.",
      relatedID: "PHONE-UDID"
    )
    let recorder = try RepositoryServiceRecorder(
      selectedXcodePathResult: makeSelectedXcodePathResult(),
      listResult: makeListResult(
        json: """
        {
          "runtimes": [
            {
              "identifier": "runtime-ios",
              "name": "iOS 26.4",
              "platform": "iOS"
            }
          ],
          "devicetypes": [],
          "devices": {
            "runtime-ios": [
              {
                "udid": "PHONE-UDID",
                "name": "iPhone 17 Pro",
                "state": "Shutdown",
                "dataPath": "/tmp/CoreSimulator/Devices/PHONE-UDID/data"
              },
              {
                "udid": "SECOND-UDID",
                "name": "iPhone 17",
                "state": "Shutdown",
                "dataPath": "/tmp/CoreSimulator/Devices/SECOND-UDID/data"
              }
            ]
          },
          "pairs": {}
        }
        """
      )
    )
    let repository = makeRepository(
      recorder: recorder,
      installedApps: { device in
        if device.id == "PHONE-UDID" {
          return AppContainerScanner.ScanResult(apps: [app], warnings: [scannerWarning])
        }

        return AppContainerScanner.ScanResult(apps: [], warnings: [])
      }
    )

    let result = await repository.refresh()

    #expect(result.succeeded)
    let snapshot = try #require(result.snapshot)
    #expect(snapshot.installedAppsByDeviceID["PHONE-UDID"] == [app])
    #expect(snapshot.installedAppsByDeviceID["SECOND-UDID"] == nil)
    #expect(snapshot.warnings.contains(scannerWarning))
  }

  @Test func refreshPreservesListFailureAfterXcodePathSucceeds() async throws {
    let xcodeCommandResult = makeCommandResult(
      executable: "xcode-select",
      arguments: ["-p"],
      stdout: "/Applications/Xcode.app/Contents/Developer\n"
    )
    let listCommandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stderr: "simctl failed",
      exitCode: 65
    )
    let diagnostic = "xcrun simctl list -j failed with exit code 65."
    let recorder = RepositoryServiceRecorder(
      selectedXcodePathResult: makeSelectedXcodePathResult(commandResult: xcodeCommandResult),
      listResult: CoreSimulatorService.ListResult(
        payload: nil,
        commandResult: listCommandResult,
        diagnostic: diagnostic
      )
    )
    let repository = makeRepository(recorder: recorder)

    let result = await repository.refresh()

    #expect(!result.succeeded)
    #expect(result.snapshot == nil)
    #expect(result.xcodeCommandResult == xcodeCommandResult)
    #expect(result.listCommandResult == listCommandResult)
    #expect(result.diagnostic == diagnostic)
    #expect(await recorder.selectedXcodePathCallCount() == 1)
    #expect(await recorder.listCallCount() == 1)
  }

  @Test func refreshCollectsWarningsForRecoverableMappingProblems() async throws {
    let recorder = try RepositoryServiceRecorder(
      selectedXcodePathResult: makeSelectedXcodePathResult(),
      listResult: makeListResult(
        json: """
        {
          "runtimes": [
            {},
            {
              "identifier": "runtime-weird",
              "name": "Mystery OS",
              "platform": "mysteryOS",
              "isAvailable": false,
              "supportedDeviceTypes": [
                {}
              ]
            },
            {
              "identifier": "runtime-known",
              "name": "iOS 26.4",
              "platform": "iOS",
              "isAvailable": true
            }
          ],
          "devicetypes": [
            {}
          ],
          "devices": {
            "": [
              {
                "udid": "SKIPPED-DEVICE"
              }
            ],
            "runtime-known": [
              {
                "udid": "DEVICE-1",
                "name": "Device 1",
                "state": "Reticulating",
                "isAvailable": false
              }
            ],
            "runtime-missing": [
              {
                "udid": "DEVICE-2",
                "name": "Device 2",
                "state": "Booted",
                "isAvailable": true,
                "deviceTypeIdentifier": "device-type-2"
              }
            ]
          },
          "pairs": {
            "PAIR-BROKEN": {
              "state": "active",
              "phone": {
                "udid": "DEVICE-1"
              },
              "watch": {
                "udid": "WATCH-MISSING"
              }
            },
            "PAIR-MISSING-WATCH": {
              "state": "active",
              "phone": {
                "udid": "DEVICE-1"
              }
            },
            "PAIR-UNKNOWN-STATE": {
              "state": "paired-ish",
              "phone": {
                "udid": "DEVICE-2"
              },
              "watch": {
                "udid": "DEVICE-1"
              }
            }
          }
        }
        """
      )
    )
    let repository = makeRepository(recorder: recorder)

    let result = await repository.refresh()

    let snapshot = try #require(result.snapshot)
    let warningIDs = Set(snapshot.warnings.map(\.id))
    #expect(warningIDs.contains("runtime-0-missing-identifier"))
    #expect(warningIDs.contains("runtime-runtime-weird-unknown-platform"))
    #expect(warningIDs.contains("runtime-runtime-weird-unavailable"))
    #expect(warningIDs.contains("runtime-runtime-weird-supported-device-type-0-missing-identifier"))
    #expect(warningIDs.contains("device-type-0-missing-identifier"))
    #expect(warningIDs.contains("device-group-missing-runtime-identifier"))
    #expect(warningIDs.contains("device-DEVICE-1-unknown-state"))
    #expect(warningIDs.contains("device-DEVICE-1-unavailable"))
    #expect(warningIDs.contains("device-DEVICE-1-missing-device-type-identifier"))
    #expect(warningIDs.contains("runtime-runtime-missing-missing-for-devices"))
    #expect(warningIDs.contains("pair-PAIR-BROKEN-phone-unavailable"))
    #expect(warningIDs.contains("pair-PAIR-BROKEN-missing-watch-device"))
    #expect(warningIDs.contains("pair-PAIR-MISSING-WATCH-missing-watch-identifier"))
    #expect(warningIDs.contains("pair-PAIR-UNKNOWN-STATE-unknown-state"))

    let brokenPair = try #require(snapshot.pairs.first { $0.id == "PAIR-BROKEN" })
    #expect(brokenPair.state == .unavailable)

    let unknownStatePair = try #require(snapshot.pairs.first { $0.id == "PAIR-UNKNOWN-STATE" })
    #expect(unknownStatePair.state == .unavailable)

    let includesMissingWatchPair = snapshot.pairs.contains { $0.id == "PAIR-MISSING-WATCH" }
    #expect(!includesMissingWatchPair)
  }

  @Test func concurrentRefreshCallsShareInFlightWork() async throws {
    let recorder = try BlockingRefreshRecorder(
      selectedXcodePathResult: makeSelectedXcodePathResult(),
      listResult: makeListResult(json: "{}")
    )
    let repository = SimulatorRepository(
      selectedXcodePath: {
        await recorder.selectedXcodePath()
      },
      list: {
        await recorder.list()
      }
    )

    async let firstResult = repository.refresh()
    await recorder.waitUntilSelectedXcodePathStarted()

    async let secondResult = repository.refresh()
    try? await Task.sleep(nanoseconds: 50_000_000)

    #expect(await recorder.selectedXcodePathCallCount() == 1)
    await recorder.releaseSelectedXcodePathLookups()

    let first = await firstResult
    let second = await secondResult
    #expect(first == second)
    #expect(await recorder.selectedXcodePathCallCount() == 1)
    #expect(await recorder.listCallCount() == 1)
  }

  private func makeRepository(
    recorder: RepositoryServiceRecorder,
    now: @escaping () -> Date = { Date(timeIntervalSince1970: 500) },
    installedApps: @escaping SimulatorRepository.InstalledAppsProvider = { _ in
      AppContainerScanner.ScanResult(apps: [], warnings: [])
    }
  ) -> SimulatorRepository {
    SimulatorRepository(
      now: now,
      selectedXcodePath: {
        await recorder.selectedXcodePath()
      },
      list: {
        await recorder.list()
      },
      installedApps: { device in
        await installedApps(device)
      }
    )
  }

  private func makeSelectedXcodePathResult(
    commandResult: CommandResult? = nil
  ) -> CoreSimulatorService.DeveloperPathResult {
    let commandResult = commandResult ?? makeCommandResult(
      executable: "xcode-select",
      arguments: ["-p"],
      stdout: "/Applications/Xcode.app/Contents/Developer\n"
    )

    return CoreSimulatorService.DeveloperPathResult(
      developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
      commandResult: commandResult,
      diagnostic: nil
    )
  }

  private func makeListResult(
    commandResult: CommandResult? = nil,
    json: String
  ) throws -> CoreSimulatorService.ListResult {
    let commandResult = commandResult ?? makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"]
    )

    return CoreSimulatorService.ListResult(
      payload: try JSONDecoder().decode(SimctlListPayload.self, from: Data(json.utf8)),
      commandResult: commandResult,
      diagnostic: nil
    )
  }

  private func makeCommandResult(
    executable: String = "xcrun",
    arguments: [String] = ["simctl", "list", "-j"],
    stdout: String = "",
    stderr: String = "",
    exitCode: Int32 = 0
  ) -> CommandResult {
    CommandResult(
      id: "\(executable)-fixture",
      executable: executable,
      arguments: arguments,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    )
  }
}

private actor RepositoryServiceRecorder {
  private let selectedXcodePathResult: CoreSimulatorService.DeveloperPathResult
  private let listResult: CoreSimulatorService.ListResult
  private var selectedXcodePathCalls = 0
  private var listCalls = 0

  init(
    selectedXcodePathResult: CoreSimulatorService.DeveloperPathResult,
    listResult: CoreSimulatorService.ListResult
  ) {
    self.selectedXcodePathResult = selectedXcodePathResult
    self.listResult = listResult
  }

  func selectedXcodePath() -> CoreSimulatorService.DeveloperPathResult {
    selectedXcodePathCalls += 1
    return selectedXcodePathResult
  }

  func list() -> CoreSimulatorService.ListResult {
    listCalls += 1
    return listResult
  }

  func selectedXcodePathCallCount() -> Int {
    selectedXcodePathCalls
  }

  func listCallCount() -> Int {
    listCalls
  }
}

private actor BlockingRefreshRecorder {
  private let selectedXcodePathResult: CoreSimulatorService.DeveloperPathResult
  private let listResult: CoreSimulatorService.ListResult
  private var selectedXcodePathCalls = 0
  private var listCalls = 0
  private var selectedXcodePathStartedWaiters: [CheckedContinuation<Void, Never>] = []
  private var selectedXcodePathReleaseContinuations: [CheckedContinuation<Void, Never>] = []
  private var selectedXcodePathLookupsReleased = false

  init(
    selectedXcodePathResult: CoreSimulatorService.DeveloperPathResult,
    listResult: CoreSimulatorService.ListResult
  ) {
    self.selectedXcodePathResult = selectedXcodePathResult
    self.listResult = listResult
  }

  func selectedXcodePath() async -> CoreSimulatorService.DeveloperPathResult {
    selectedXcodePathCalls += 1
    resumeSelectedXcodePathStartedWaiters()

    if !selectedXcodePathLookupsReleased {
      await withCheckedContinuation { continuation in
        selectedXcodePathReleaseContinuations.append(continuation)
      }
    }

    return selectedXcodePathResult
  }

  func list() -> CoreSimulatorService.ListResult {
    listCalls += 1
    return listResult
  }

  func waitUntilSelectedXcodePathStarted() async {
    guard selectedXcodePathCalls == 0 else {
      return
    }

    await withCheckedContinuation { continuation in
      selectedXcodePathStartedWaiters.append(continuation)
    }
  }

  func releaseSelectedXcodePathLookups() {
    selectedXcodePathLookupsReleased = true
    let continuations = selectedXcodePathReleaseContinuations
    selectedXcodePathReleaseContinuations.removeAll()
    continuations.forEach { $0.resume() }
  }

  func selectedXcodePathCallCount() -> Int {
    selectedXcodePathCalls
  }

  func listCallCount() -> Int {
    listCalls
  }

  private func resumeSelectedXcodePathStartedWaiters() {
    let waiters = selectedXcodePathStartedWaiters
    selectedXcodePathStartedWaiters.removeAll()
    waiters.forEach { $0.resume() }
  }
}
