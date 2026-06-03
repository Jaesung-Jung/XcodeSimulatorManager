# SimControl MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the SimControl MVP described in `docs/FUNCTIONAL_SPEC.md`: a macOS SwiftUI app that inspects and operates simulator devices for the Active Xcode through `xcrun simctl`.

**Architecture:** Create a Swift package with a testable `SimControlCore` library and a thin `SimControlApp` SwiftUI executable. `SimControlCore` owns domain models, `simctl` command construction/execution, JSON parsing, device operations, target app installation/launching, environment diagnostics, and window-layout persistence; SwiftUI views consume those services through an observable app model.

**Tech Stack:** Swift 6, SwiftUI for macOS, Swift Testing, Foundation `Process`, `JSONDecoder`, `PropertyListSerialization`, `UserDefaults`.

---

## Scope Check

The functional spec covers one coherent MVP: a simulator management app. It touches multiple concerns, but they are dependent slices of the same product and can be implemented as vertical tasks. Runtime acquisition, logs, menu bar control, Xcode switching, pairing mutation, and app build inputs are explicitly excluded.

## File Structure

- Create: `Package.swift` - Swift package manifest with `SimControlCore`, `SimControlApp`, and tests.
- Create: `Sources/SimControlCore/Domain/SimulatorModels.swift` - domain enums and value types.
- Create: `Sources/SimControlCore/Domain/PlatformClassifier.swift` - supported/unknown platform classification.
- Create: `Sources/SimControlCore/Domain/DeviceNameGenerator.swift` - default and collision-safe simulator names.
- Create: `Sources/SimControlCore/Simctl/CommandRunning.swift` - command runner abstraction and `Process` implementation.
- Create: `Sources/SimControlCore/Simctl/SimctlClient.swift` - `xcrun simctl` command API.
- Create: `Sources/SimControlCore/Simctl/SimctlListParser.swift` - parser for `simctl list --json` output.
- Create: `Sources/SimControlCore/Services/EnvironmentDiagnostics.swift` - Active Xcode and `simctl` availability checks.
- Create: `Sources/SimControlCore/Services/InventoryService.swift` - refreshable inventory facade.
- Create: `Sources/SimControlCore/Services/DeviceOperationService.swift` - boot/shutdown/open/erase/delete/create operations.
- Create: `Sources/SimControlCore/Services/TargetAppService.swift` - `.app` bundle validation, install, and launch.
- Create: `Sources/SimControlCore/Services/WindowLayoutStore.swift` - window size and split-position persistence only.
- Create: `Sources/SimControlApp/SimControlApp.swift` - SwiftUI entry point.
- Create: `Sources/SimControlApp/AppModel.swift` - observable UI state and async actions.
- Create: `Sources/SimControlApp/Views/ContentView.swift` - single-window layout.
- Create: `Sources/SimControlApp/Views/DeviceInventoryView.swift` - device table and filters.
- Create: `Sources/SimControlApp/Views/DeviceDetailView.swift` - selected device actions and target app controls.
- Create: `Sources/SimControlApp/Views/RuntimeCatalogView.swift` - read-only runtime catalog.
- Create: `Sources/SimControlApp/Views/CreateDeviceSheet.swift` - device creation flow.
- Create: `Sources/SimControlApp/Views/ResultPanel.swift` - `simctl` output and copyable results.
- Create: `Tests/SimControlCoreTests/*.swift` - Swift Testing coverage for core behavior.
- Create: `Tests/SimControlCoreTests/Fixtures/simctl-list.json` - representative `simctl list --json` fixture.

## Task 1: Bootstrap Swift Package and Empty App

**Files:**
- Create: `Package.swift`
- Create: `Sources/SimControlApp/SimControlApp.swift`
- Create: `Sources/SimControlCore/Domain/SimulatorModels.swift`
- Create: `Tests/SimControlCoreTests/BootstrapTests.swift`

- [ ] **Step 1: Write package manifest**

Use this complete `Package.swift`:

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "SimControl",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "SimControlCore", targets: ["SimControlCore"]),
        .executable(name: "SimControlApp", targets: ["SimControlApp"])
    ],
    targets: [
        .target(name: "SimControlCore"),
        .executableTarget(
            name: "SimControlApp",
            dependencies: ["SimControlCore"]
        ),
        .testTarget(
            name: "SimControlCoreTests",
            dependencies: ["SimControlCore"],
            resources: [.copy("Fixtures")]
        )
    ]
)
```

- [ ] **Step 2: Add the smallest core type**

Create `Sources/SimControlCore/Domain/SimulatorModels.swift`:

```swift
import Foundation

public enum SupportedPlatform: String, CaseIterable, Sendable, Codable, Equatable {
    case iOS
    case watchOS
    case tvOS
    case visionOS
    case other
}
```

- [ ] **Step 3: Add the smallest SwiftUI app**

Create `Sources/SimControlApp/SimControlApp.swift`:

```swift
import SwiftUI

@main
struct SimControlApp: App {
    var body: some Scene {
        WindowGroup {
            Text("SimControl")
                .frame(minWidth: 900, minHeight: 600)
        }
    }
}
```

- [ ] **Step 4: Add a bootstrap test**

Create `Tests/SimControlCoreTests/BootstrapTests.swift`:

```swift
import Testing
import SimControlCore

@Test func supportedPlatformsIncludeMVPPlatforms() {
    #expect(SupportedPlatform.allCases.contains(.iOS))
    #expect(SupportedPlatform.allCases.contains(.watchOS))
    #expect(SupportedPlatform.allCases.contains(.tvOS))
    #expect(SupportedPlatform.allCases.contains(.visionOS))
}
```

- [ ] **Step 5: Verify**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 6: Commit**

```bash
git add Package.swift Sources Tests
git commit -m "chore: bootstrap Swift package"
```

## Task 2: Domain Models and Platform Classification

**Files:**
- Modify: `Sources/SimControlCore/Domain/SimulatorModels.swift`
- Create: `Sources/SimControlCore/Domain/PlatformClassifier.swift`
- Create: `Sources/SimControlCore/Domain/DeviceNameGenerator.swift`
- Create: `Tests/SimControlCoreTests/DomainModelTests.swift`

- [ ] **Step 1: Write domain tests**

Create `Tests/SimControlCoreTests/DomainModelTests.swift`:

```swift
import Testing
import SimControlCore

@Test(arguments: [
    ("com.apple.CoreSimulator.SimRuntime.iOS-18-4", SupportedPlatform.iOS),
    ("com.apple.CoreSimulator.SimRuntime.watchOS-11-4", SupportedPlatform.watchOS),
    ("com.apple.CoreSimulator.SimRuntime.tvOS-18-4", SupportedPlatform.tvOS),
    ("com.apple.CoreSimulator.SimRuntime.xrOS-2-4", SupportedPlatform.visionOS),
    ("com.apple.CoreSimulator.SimRuntime.someFutureOS-1-0", SupportedPlatform.other)
])
func classifiesRuntimeIdentifier(identifier: String, expected: SupportedPlatform) {
    #expect(PlatformClassifier.platform(forRuntimeIdentifier: identifier) == expected)
}

@Test func generatesNumberedNameWhenCollisionExists() {
    let existing: Set<String> = [
        "iPhone 16 Pro - iOS 18.4",
        "iPhone 16 Pro - iOS 18.4 (2)"
    ]

    let name = DeviceNameGenerator.uniqueName(
        baseName: "iPhone 16 Pro - iOS 18.4",
        existingNames: existing
    )

    #expect(name == "iPhone 16 Pro - iOS 18.4 (3)")
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter DomainModelTests`

Expected: fails because `PlatformClassifier` and `DeviceNameGenerator` are not defined.

- [ ] **Step 3: Implement models and helpers**

Replace `Sources/SimControlCore/Domain/SimulatorModels.swift` with:

```swift
import Foundation

public enum SupportedPlatform: String, CaseIterable, Sendable, Codable, Equatable, Hashable {
    case iOS
    case watchOS
    case tvOS
    case visionOS
    case other
}

public enum SimulatorDeviceState: String, Sendable, Codable, Equatable, Hashable {
    case booted = "Booted"
    case shutdown = "Shutdown"
    case creating = "Creating"
    case unavailable = "Unavailable"
    case unknown
}

public struct SimulatorRuntime: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let platform: SupportedPlatform
    public let version: String
    public let buildVersion: String?
    public let identifier: String
    public let isAvailable: Bool
    public let availabilityError: String?
    public let deviceCount: Int

    public init(id: String, name: String, platform: SupportedPlatform, version: String, buildVersion: String?, identifier: String, isAvailable: Bool, availabilityError: String?, deviceCount: Int) {
        self.id = id
        self.name = name
        self.platform = platform
        self.version = version
        self.buildVersion = buildVersion
        self.identifier = identifier
        self.isAvailable = isAvailable
        self.availabilityError = availabilityError
        self.deviceCount = deviceCount
    }
}

public struct SimulatorDevice: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let udid: String
    public let platform: SupportedPlatform
    public let runtimeIdentifier: String
    public let runtimeVersion: String
    public let deviceTypeIdentifier: String
    public let deviceTypeName: String
    public let state: SimulatorDeviceState
    public let isAvailable: Bool
    public let availabilityError: String?
    public let pairingDescription: String?

    public init(id: String, name: String, udid: String, platform: SupportedPlatform, runtimeIdentifier: String, runtimeVersion: String, deviceTypeIdentifier: String, deviceTypeName: String, state: SimulatorDeviceState, isAvailable: Bool, availabilityError: String?, pairingDescription: String?) {
        self.id = id
        self.name = name
        self.udid = udid
        self.platform = platform
        self.runtimeIdentifier = runtimeIdentifier
        self.runtimeVersion = runtimeVersion
        self.deviceTypeIdentifier = deviceTypeIdentifier
        self.deviceTypeName = deviceTypeName
        self.state = state
        self.isAvailable = isAvailable
        self.availabilityError = availabilityError
        self.pairingDescription = pairingDescription
    }
}

public struct DeviceType: Identifiable, Sendable, Codable, Equatable, Hashable {
    public let id: String
    public let name: String
    public let identifier: String
    public let supportedPlatforms: Set<SupportedPlatform>

    public init(id: String, name: String, identifier: String, supportedPlatforms: Set<SupportedPlatform>) {
        self.id = id
        self.name = name
        self.identifier = identifier
        self.supportedPlatforms = supportedPlatforms
    }
}

public struct SimulatorInventory: Sendable, Equatable {
    public let devices: [SimulatorDevice]
    public let runtimes: [SimulatorRuntime]
    public let deviceTypes: [DeviceType]

    public init(devices: [SimulatorDevice], runtimes: [SimulatorRuntime], deviceTypes: [DeviceType]) {
        self.devices = devices
        self.runtimes = runtimes
        self.deviceTypes = deviceTypes
    }
}
```

Create `Sources/SimControlCore/Domain/PlatformClassifier.swift`:

```swift
public enum PlatformClassifier {
    public static func platform(forRuntimeIdentifier identifier: String) -> SupportedPlatform {
        if identifier.contains(".iOS-") { return .iOS }
        if identifier.contains(".watchOS-") { return .watchOS }
        if identifier.contains(".tvOS-") { return .tvOS }
        if identifier.contains(".visionOS-") || identifier.contains(".xrOS-") { return .visionOS }
        return .other
    }
}
```

Create `Sources/SimControlCore/Domain/DeviceNameGenerator.swift`:

```swift
public enum DeviceNameGenerator {
    public static func defaultName(deviceTypeName: String, runtimeName: String) -> String {
        "\(deviceTypeName) - \(runtimeName)"
    }

    public static func uniqueName(baseName: String, existingNames: Set<String>) -> String {
        guard existingNames.contains(baseName) else { return baseName }

        var suffix = 2
        while existingNames.contains("\(baseName) (\(suffix))") {
            suffix += 1
        }
        return "\(baseName) (\(suffix))"
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter DomainModelTests`

Expected: all `DomainModelTests` pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlCore/Domain Tests/SimControlCoreTests/DomainModelTests.swift
git commit -m "feat: add simulator domain models"
```

## Task 3: Command Runner and simctl Client

**Files:**
- Create: `Sources/SimControlCore/Simctl/CommandRunning.swift`
- Create: `Sources/SimControlCore/Simctl/SimctlClient.swift`
- Create: `Tests/SimControlCoreTests/SimctlClientTests.swift`

- [ ] **Step 1: Write command-construction tests**

Create `Tests/SimControlCoreTests/SimctlClientTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

final class RecordingCommandRunner: CommandRunning, @unchecked Sendable {
    var invocations: [(String, [String])] = []
    var result = CommandResult(exitCode: 0, stdout: Data(), stderr: Data())

    func run(executable: String, arguments: [String]) async throws -> CommandResult {
        invocations.append((executable, arguments))
        return result
    }
}

@Test func listUsesXcrunSimctlJson() async throws {
    let runner = RecordingCommandRunner()
    let client = SimctlClient(runner: runner)

    _ = try await client.list()

    #expect(runner.invocations == [
        ("xcrun", ["simctl", "list", "--json"])
    ])
}

@Test func bootUsesDeviceUDID() async throws {
    let runner = RecordingCommandRunner()
    let client = SimctlClient(runner: runner)

    _ = try await client.boot(udid: "DEVICE-1")

    #expect(runner.invocations == [
        ("xcrun", ["simctl", "boot", "DEVICE-1"])
    ])
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter SimctlClientTests`

Expected: fails because command runner and client do not exist.

- [ ] **Step 3: Implement command runner and client**

Create `Sources/SimControlCore/Simctl/CommandRunning.swift`:

```swift
import Foundation

public struct CommandResult: Sendable, Equatable {
    public let exitCode: Int32
    public let stdout: Data
    public let stderr: Data

    public init(exitCode: Int32, stdout: Data, stderr: Data) {
        self.exitCode = exitCode
        self.stdout = stdout
        self.stderr = stderr
    }

    public var stdoutText: String {
        String(data: stdout, encoding: .utf8) ?? ""
    }

    public var stderrText: String {
        String(data: stderr, encoding: .utf8) ?? ""
    }
}

public protocol CommandRunning: Sendable {
    func run(executable: String, arguments: [String]) async throws -> CommandResult
}

public enum CommandRunnerError: Error, Equatable {
    case launchFailed(String)
}

public struct ProcessCommandRunner: CommandRunning {
    public init() {}

    public func run(executable: String, arguments: [String]) async throws -> CommandResult {
        try await Task.detached {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/env")
            process.arguments = [executable] + arguments

            let output = Pipe()
            let error = Pipe()
            process.standardOutput = output
            process.standardError = error

            do {
                try process.run()
            } catch {
                throw CommandRunnerError.launchFailed(error.localizedDescription)
            }

            process.waitUntilExit()
            return CommandResult(
                exitCode: process.terminationStatus,
                stdout: output.fileHandleForReading.readDataToEndOfFile(),
                stderr: error.fileHandleForReading.readDataToEndOfFile()
            )
        }.value
    }
}
```

Create `Sources/SimControlCore/Simctl/SimctlClient.swift`:

```swift
import Foundation

public struct SimctlClient: Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    @discardableResult public func list() async throws -> CommandResult {
        try await simctl(["list", "--json"])
    }

    @discardableResult public func boot(udid: String) async throws -> CommandResult {
        try await simctl(["boot", udid])
    }

    @discardableResult public func shutdown(udid: String) async throws -> CommandResult {
        try await simctl(["shutdown", udid])
    }

    @discardableResult public func erase(udid: String) async throws -> CommandResult {
        try await simctl(["erase", udid])
    }

    @discardableResult public func delete(udid: String) async throws -> CommandResult {
        try await simctl(["delete", udid])
    }

    @discardableResult public func create(name: String, deviceTypeIdentifier: String, runtimeIdentifier: String) async throws -> CommandResult {
        try await simctl(["create", name, deviceTypeIdentifier, runtimeIdentifier])
    }

    @discardableResult public func install(udid: String, appBundlePath: String) async throws -> CommandResult {
        try await simctl(["install", udid, appBundlePath])
    }

    @discardableResult public func launch(udid: String, bundleIdentifier: String) async throws -> CommandResult {
        try await simctl(["launch", udid, bundleIdentifier])
    }

    @discardableResult public func openSimulator(udid: String) async throws -> CommandResult {
        try await runner.run(executable: "open", arguments: ["-a", "Simulator", "--args", "-CurrentDeviceUDID", udid])
    }

    private func simctl(_ arguments: [String]) async throws -> CommandResult {
        try await runner.run(executable: "xcrun", arguments: ["simctl"] + arguments)
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter SimctlClientTests`

Expected: all `SimctlClientTests` pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlCore/Simctl Tests/SimControlCoreTests/SimctlClientTests.swift
git commit -m "feat: add simctl command client"
```

## Task 4: Parse simctl Inventory JSON

**Files:**
- Create: `Sources/SimControlCore/Simctl/SimctlListParser.swift`
- Create: `Tests/SimControlCoreTests/Fixtures/simctl-list.json`
- Create: `Tests/SimControlCoreTests/SimctlListParserTests.swift`

- [ ] **Step 1: Add fixture**

Create `Tests/SimControlCoreTests/Fixtures/simctl-list.json`:

```json
{
  "devicetypes": [
    {
      "name": "iPhone 16 Pro",
      "identifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro"
    }
  ],
  "runtimes": [
    {
      "bundlePath": "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.4.simruntime",
      "buildversion": "22E238",
      "runtimeRoot": "/Library/Developer/CoreSimulator/Profiles/Runtimes/iOS 18.4.simruntime/Contents/Resources/RuntimeRoot",
      "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-18-4",
      "version": "18.4",
      "isAvailable": true,
      "name": "iOS 18.4"
    }
  ],
  "devices": {
    "com.apple.CoreSimulator.SimRuntime.iOS-18-4": [
      {
        "lastBootedAt": "2026-05-28T01:00:00Z",
        "dataPath": "/Users/example/Library/Developer/CoreSimulator/Devices/DEVICE-1/data",
        "dataPathSize": 1,
        "logPath": "/Users/example/Library/Logs/CoreSimulator/DEVICE-1",
        "udid": "DEVICE-1",
        "isAvailable": true,
        "deviceTypeIdentifier": "com.apple.CoreSimulator.SimDeviceType.iPhone-16-Pro",
        "state": "Shutdown",
        "name": "iPhone 16 Pro"
      }
    ]
  },
  "pairs": { "watch": [] }
}
```

- [ ] **Step 2: Write parser test**

Create `Tests/SimControlCoreTests/SimctlListParserTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

@Test func parsesInventoryFromSimctlListJSON() throws {
    let url = try #require(Bundle.module.url(forResource: "simctl-list", withExtension: "json"))
    let data = try Data(contentsOf: url)

    let inventory = try SimctlListParser().parse(data)

    #expect(inventory.runtimes.count == 1)
    #expect(inventory.runtimes[0].platform == .iOS)
    #expect(inventory.runtimes[0].version == "18.4")
    #expect(inventory.runtimes[0].deviceCount == 1)
    #expect(inventory.devices.count == 1)
    #expect(inventory.devices[0].udid == "DEVICE-1")
    #expect(inventory.devices[0].deviceTypeName == "iPhone 16 Pro")
    #expect(inventory.devices[0].state == .shutdown)
}
```

- [ ] **Step 3: Run test to verify failure**

Run: `swift test --filter SimctlListParserTests`

Expected: fails because `SimctlListParser` does not exist.

- [ ] **Step 4: Implement parser**

Create `Sources/SimControlCore/Simctl/SimctlListParser.swift`:

```swift
import Foundation

public struct SimctlListParser: Sendable {
    public init() {}

    public func parse(_ data: Data) throws -> SimulatorInventory {
        let root = try JSONDecoder().decode(SimctlListResponse.self, from: data)
        let deviceTypeNames = Dictionary(uniqueKeysWithValues: root.devicetypes.map { ($0.identifier, $0.name) })
        let devicesByRuntime = root.devices

        let runtimes = root.runtimes.map { runtime in
            let platform = PlatformClassifier.platform(forRuntimeIdentifier: runtime.identifier)
            let deviceCount = devicesByRuntime[runtime.identifier]?.count ?? 0
            return SimulatorRuntime(
                id: runtime.identifier,
                name: runtime.name,
                platform: platform,
                version: runtime.version,
                buildVersion: runtime.buildversion,
                identifier: runtime.identifier,
                isAvailable: runtime.isAvailable,
                availabilityError: runtime.availabilityError,
                deviceCount: deviceCount
            )
        }

        let runtimeByIdentifier = Dictionary(uniqueKeysWithValues: runtimes.map { ($0.identifier, $0) })
        let devices = devicesByRuntime.flatMap { runtimeIdentifier, rawDevices in
            rawDevices.map { raw in
                let runtime = runtimeByIdentifier[runtimeIdentifier]
                let state = SimulatorDeviceState(rawValue: raw.state) ?? .unknown
                return SimulatorDevice(
                    id: raw.udid,
                    name: raw.name,
                    udid: raw.udid,
                    platform: runtime?.platform ?? .other,
                    runtimeIdentifier: runtimeIdentifier,
                    runtimeVersion: runtime?.version ?? "",
                    deviceTypeIdentifier: raw.deviceTypeIdentifier,
                    deviceTypeName: deviceTypeNames[raw.deviceTypeIdentifier] ?? raw.deviceTypeIdentifier,
                    state: raw.isAvailable ? state : .unavailable,
                    isAvailable: raw.isAvailable,
                    availabilityError: raw.availabilityError,
                    pairingDescription: nil
                )
            }
        }.sorted { $0.name.localizedStandardCompare($1.name) == .orderedAscending }

        let deviceTypes = root.devicetypes.map { raw in
            DeviceType(
                id: raw.identifier,
                name: raw.name,
                identifier: raw.identifier,
                supportedPlatforms: supportedPlatforms(forDeviceTypeIdentifier: raw.identifier)
            )
        }

        return SimulatorInventory(devices: devices, runtimes: runtimes, deviceTypes: deviceTypes)
    }

    private func supportedPlatforms(forDeviceTypeIdentifier identifier: String) -> Set<SupportedPlatform> {
        if identifier.contains("Watch") { return [.watchOS] }
        if identifier.contains("Apple-TV") { return [.tvOS] }
        if identifier.contains("Apple-Vision") { return [.visionOS] }
        if identifier.contains("iPhone") || identifier.contains("iPad") { return [.iOS] }
        return [.other]
    }
}

private struct SimctlListResponse: Decodable {
    let devicetypes: [RawDeviceType]
    let runtimes: [RawRuntime]
    let devices: [String: [RawDevice]]
}

private struct RawDeviceType: Decodable {
    let name: String
    let identifier: String
}

private struct RawRuntime: Decodable {
    let buildversion: String?
    let identifier: String
    let version: String
    let isAvailable: Bool
    let name: String
    let availabilityError: String?
}

private struct RawDevice: Decodable {
    let udid: String
    let isAvailable: Bool
    let deviceTypeIdentifier: String
    let state: String
    let name: String
    let availabilityError: String?
}
```

- [ ] **Step 5: Verify**

Run: `swift test --filter SimctlListParserTests`

Expected: parser test passes.

- [ ] **Step 6: Commit**

```bash
git add Sources/SimControlCore/Simctl/SimctlListParser.swift Tests/SimControlCoreTests
git commit -m "feat: parse simctl inventory"
```

## Task 5: Environment Diagnostics and Inventory Refresh

**Files:**
- Create: `Sources/SimControlCore/Services/EnvironmentDiagnostics.swift`
- Create: `Sources/SimControlCore/Services/InventoryService.swift`
- Create: `Tests/SimControlCoreTests/EnvironmentDiagnosticsTests.swift`
- Create: `Tests/SimControlCoreTests/InventoryServiceTests.swift`

- [ ] **Step 1: Write service tests**

Create `Tests/SimControlCoreTests/EnvironmentDiagnosticsTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

@Test func diagnosticsReportUnavailableWhenSimctlFails() async throws {
    let runner = RecordingCommandRunner()
    runner.result = CommandResult(exitCode: 1, stdout: Data(), stderr: Data("xcode-select: error".utf8))
    let diagnostics = EnvironmentDiagnostics(runner: runner)

    let status = await diagnostics.check()

    #expect(status.isAvailable == false)
    #expect(status.message.contains("xcode-select: error"))
}
```

Create `Tests/SimControlCoreTests/InventoryServiceTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

@Test func refreshParsesInventoryWhenListSucceeds() async throws {
    let url = try #require(Bundle.module.url(forResource: "simctl-list", withExtension: "json"))
    let data = try Data(contentsOf: url)
    let runner = RecordingCommandRunner()
    runner.result = CommandResult(exitCode: 0, stdout: data, stderr: Data())

    let service = InventoryService(client: SimctlClient(runner: runner), parser: SimctlListParser())
    let inventory = try await service.refresh()

    #expect(inventory.devices.count == 1)
    #expect(inventory.runtimes.count == 1)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter diagnosticsReportUnavailableWhenSimctlFails && swift test --filter refreshParsesInventoryWhenListSucceeds`

Expected: fails because service types are not defined.

- [ ] **Step 3: Implement services**

Create `Sources/SimControlCore/Services/EnvironmentDiagnostics.swift`:

```swift
import Foundation

public struct EnvironmentStatus: Sendable, Equatable {
    public let isAvailable: Bool
    public let activeXcodePath: String?
    public let message: String

    public init(isAvailable: Bool, activeXcodePath: String?, message: String) {
        self.isAvailable = isAvailable
        self.activeXcodePath = activeXcodePath
        self.message = message
    }
}

public struct EnvironmentDiagnostics: Sendable {
    private let runner: CommandRunning

    public init(runner: CommandRunning = ProcessCommandRunner()) {
        self.runner = runner
    }

    public func check() async -> EnvironmentStatus {
        let xcodePathResult = try? await runner.run(executable: "xcode-select", arguments: ["-p"])
        let simctlResult = try? await runner.run(executable: "xcrun", arguments: ["simctl", "list", "--json"])

        let path = xcodePathResult?.stdoutText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard let simctlResult, simctlResult.exitCode == 0 else {
            let message = simctlResult?.stderrText.isEmpty == false ? simctlResult!.stderrText : "xcrun simctl is unavailable."
            return EnvironmentStatus(isAvailable: false, activeXcodePath: path, message: message)
        }

        return EnvironmentStatus(isAvailable: true, activeXcodePath: path, message: "xcrun simctl is available.")
    }
}
```

Create `Sources/SimControlCore/Services/InventoryService.swift`:

```swift
import Foundation

public struct InventoryService: Sendable {
    private let client: SimctlClient
    private let parser: SimctlListParser

    public init(client: SimctlClient = SimctlClient(), parser: SimctlListParser = SimctlListParser()) {
        self.client = client
        self.parser = parser
    }

    public func refresh() async throws -> SimulatorInventory {
        let result = try await client.list()
        if result.exitCode != 0 {
            throw SimctlOperationError(commandName: "list", deviceName: nil, udid: nil, result: result)
        }
        return try parser.parse(result.stdout)
    }
}

public struct SimctlOperationError: Error, Sendable, Equatable {
    public let commandName: String
    public let deviceName: String?
    public let udid: String?
    public let result: CommandResult

    public init(commandName: String, deviceName: String?, udid: String?, result: CommandResult) {
        self.commandName = commandName
        self.deviceName = deviceName
        self.udid = udid
        self.result = result
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter diagnosticsReportUnavailableWhenSimctlFails && swift test --filter refreshParsesInventoryWhenListSucceeds`

Expected: diagnostics and inventory tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlCore/Services Tests/SimControlCoreTests
git commit -m "feat: add environment diagnostics and inventory refresh"
```

## Task 6: Device Operations

**Files:**
- Create: `Sources/SimControlCore/Services/DeviceOperationService.swift`
- Create: `Tests/SimControlCoreTests/DeviceOperationServiceTests.swift`

- [ ] **Step 1: Write operation tests**

Create `Tests/SimControlCoreTests/DeviceOperationServiceTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

@Test func deleteBootedDeviceShutsDownBeforeDelete() async throws {
    let runner = RecordingCommandRunner()
    let service = DeviceOperationService(client: SimctlClient(runner: runner))
    let device = SimulatorDevice(
        id: "DEVICE-1",
        name: "iPhone 16 Pro",
        udid: "DEVICE-1",
        platform: .iOS,
        runtimeIdentifier: "runtime",
        runtimeVersion: "18.4",
        deviceTypeIdentifier: "type",
        deviceTypeName: "iPhone 16 Pro",
        state: .booted,
        isAvailable: true,
        availabilityError: nil,
        pairingDescription: nil
    )

    _ = try await service.delete(device: device)

    #expect(runner.invocations.map(\.1) == [
        ["simctl", "shutdown", "DEVICE-1"],
        ["simctl", "delete", "DEVICE-1"]
    ])
}

@Test func unavailableDeviceOnlyAllowsDelete() {
    let device = SimulatorDevice(
        id: "DEVICE-1",
        name: "Unavailable",
        udid: "DEVICE-1",
        platform: .iOS,
        runtimeIdentifier: "runtime",
        runtimeVersion: "18.4",
        deviceTypeIdentifier: "type",
        deviceTypeName: "iPhone",
        state: .unavailable,
        isAvailable: false,
        availabilityError: "missing runtime",
        pairingDescription: nil
    )

    #expect(DeviceOperationPolicy.allowedOperations(for: device) == [.delete])
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter DeviceOperationServiceTests`

Expected: fails because operation service and policy are not defined.

- [ ] **Step 3: Implement operations**

Create `Sources/SimControlCore/Services/DeviceOperationService.swift`:

```swift
import Foundation

public enum DeviceOperation: String, Sendable, CaseIterable, Hashable {
    case boot
    case shutdown
    case openInSimulator
    case erase
    case delete
}

public enum DeviceOperationPolicy {
    public static func allowedOperations(for device: SimulatorDevice) -> Set<DeviceOperation> {
        if device.state == .unavailable || !device.isAvailable {
            return [.delete]
        }

        switch device.state {
        case .booted:
            return [.shutdown, .openInSimulator, .erase, .delete]
        case .shutdown:
            return [.boot, .erase, .delete]
        case .creating:
            return []
        case .unavailable:
            return [.delete]
        case .unknown:
            return [.delete]
        }
    }
}

public struct DeviceOperationService: Sendable {
    private let client: SimctlClient

    public init(client: SimctlClient = SimctlClient()) {
        self.client = client
    }

    public func boot(device: SimulatorDevice) async throws -> CommandResult {
        try await client.boot(udid: device.udid)
    }

    public func shutdown(device: SimulatorDevice) async throws -> CommandResult {
        try await client.shutdown(udid: device.udid)
    }

    public func openInSimulator(device: SimulatorDevice) async throws -> CommandResult {
        try await client.openSimulator(udid: device.udid)
    }

    public func erase(device: SimulatorDevice) async throws -> CommandResult {
        try await client.erase(udid: device.udid)
    }

    public func delete(device: SimulatorDevice) async throws -> [CommandResult] {
        var results: [CommandResult] = []
        if device.state == .booted {
            results.append(try await client.shutdown(udid: device.udid))
        }
        results.append(try await client.delete(udid: device.udid))
        return results
    }

    public func create(name: String, deviceTypeIdentifier: String, runtimeIdentifier: String) async throws -> CommandResult {
        try await client.create(name: name, deviceTypeIdentifier: deviceTypeIdentifier, runtimeIdentifier: runtimeIdentifier)
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter DeviceOperationServiceTests`

Expected: device operation tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlCore/Services/DeviceOperationService.swift Tests/SimControlCoreTests/DeviceOperationServiceTests.swift
git commit -m "feat: add device operations"
```

## Task 7: Target App Bundle Install and Launch

**Files:**
- Create: `Sources/SimControlCore/Services/TargetAppService.swift`
- Create: `Tests/SimControlCoreTests/TargetAppServiceTests.swift`

- [ ] **Step 1: Write target app tests**

Create `Tests/SimControlCoreTests/TargetAppServiceTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

@Test func readsBundleIdentifierFromAppBundle() throws {
    let root = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let app = root.appending(path: "Demo.app")
    let contents = app.appending(path: "Contents")
    try FileManager.default.createDirectory(at: contents, withIntermediateDirectories: true)
    let plist = contents.appending(path: "Info.plist")
    let data = try PropertyListSerialization.data(
        fromPropertyList: ["CFBundleIdentifier": "com.example.Demo"],
        format: .xml,
        options: 0
    )
    try data.write(to: plist)
    defer { try? FileManager.default.removeItem(at: root) }

    let identifier = try TargetAppBundle(url: app).bundleIdentifier()

    #expect(identifier == "com.example.Demo")
}

@Test func installIsDisabledForShutdownDeviceByPolicy() {
    #expect(TargetAppPolicy.canInstallOrLaunch(deviceState: .shutdown) == false)
    #expect(TargetAppPolicy.canInstallOrLaunch(deviceState: .booted) == true)
}
```

- [ ] **Step 2: Run tests to verify failure**

Run: `swift test --filter TargetAppServiceTests`

Expected: fails because target app types are not defined.

- [ ] **Step 3: Implement target app service**

Create `Sources/SimControlCore/Services/TargetAppService.swift`:

```swift
import Foundation

public struct TargetAppBundle: Sendable, Equatable {
    public let url: URL

    public init(url: URL) {
        self.url = url
    }

    public func bundleIdentifier() throws -> String {
        let plistURL = url.appending(path: "Contents/Info.plist")
        let data = try Data(contentsOf: plistURL)
        let plist = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        guard let dictionary = plist as? [String: Any],
              let identifier = dictionary["CFBundleIdentifier"] as? String,
              !identifier.isEmpty else {
            throw TargetAppError.missingBundleIdentifier
        }
        return identifier
    }
}

public enum TargetAppError: Error, Equatable {
    case missingBundleIdentifier
}

public enum TargetAppPolicy {
    public static func canInstallOrLaunch(deviceState: SimulatorDeviceState) -> Bool {
        deviceState == .booted
    }
}

public struct TargetAppService: Sendable {
    private let client: SimctlClient

    public init(client: SimctlClient = SimctlClient()) {
        self.client = client
    }

    public func install(bundle: TargetAppBundle, on device: SimulatorDevice) async throws -> CommandResult {
        try await client.install(udid: device.udid, appBundlePath: bundle.url.path)
    }

    public func launch(bundle: TargetAppBundle, on device: SimulatorDevice) async throws -> CommandResult {
        let bundleIdentifier = try bundle.bundleIdentifier()
        return try await client.launch(udid: device.udid, bundleIdentifier: bundleIdentifier)
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter TargetAppServiceTests`

Expected: target app tests pass.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlCore/Services/TargetAppService.swift Tests/SimControlCoreTests/TargetAppServiceTests.swift
git commit -m "feat: add target app install and launch service"
```

## Task 8: Window Layout Persistence Only

**Files:**
- Create: `Sources/SimControlCore/Services/WindowLayoutStore.swift`
- Create: `Tests/SimControlCoreTests/WindowLayoutStoreTests.swift`

- [ ] **Step 1: Write persistence tests**

Create `Tests/SimControlCoreTests/WindowLayoutStoreTests.swift`:

```swift
import Foundation
import Testing
import SimControlCore

@Test func storesOnlyWindowLayoutValues() {
    let defaults = UserDefaults(suiteName: "WindowLayoutStoreTests-\(UUID().uuidString)")!
    let store = WindowLayoutStore(defaults: defaults)

    store.save(WindowLayout(width: 1200, height: 760, sidebarWidth: 220, detailWidth: 320))
    let loaded = store.load()

    #expect(loaded == WindowLayout(width: 1200, height: 760, sidebarWidth: 220, detailWidth: 320))
    #expect(defaults.dictionaryRepresentation().keys.contains("lastSelectedDeviceUDID") == false)
}
```

- [ ] **Step 2: Run test to verify failure**

Run: `swift test --filter WindowLayoutStoreTests`

Expected: fails because `WindowLayoutStore` does not exist.

- [ ] **Step 3: Implement layout store**

Create `Sources/SimControlCore/Services/WindowLayoutStore.swift`:

```swift
import Foundation

public struct WindowLayout: Sendable, Codable, Equatable {
    public let width: Double
    public let height: Double
    public let sidebarWidth: Double
    public let detailWidth: Double

    public init(width: Double, height: Double, sidebarWidth: Double, detailWidth: Double) {
        self.width = width
        self.height = height
        self.sidebarWidth = sidebarWidth
        self.detailWidth = detailWidth
    }
}

public struct WindowLayoutStore: Sendable {
    private let defaults: UserDefaults
    private let key = "windowLayout"

    public init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
    }

    public func save(_ layout: WindowLayout) {
        guard let data = try? JSONEncoder().encode(layout) else { return }
        defaults.set(data, forKey: key)
    }

    public func load() -> WindowLayout? {
        guard let data = defaults.data(forKey: key) else { return nil }
        return try? JSONDecoder().decode(WindowLayout.self, from: data)
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter WindowLayoutStoreTests`

Expected: layout store test passes.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlCore/Services/WindowLayoutStore.swift Tests/SimControlCoreTests/WindowLayoutStoreTests.swift
git commit -m "feat: persist window layout"
```

## Task 9: App Model and Refresh Lifecycle

**Files:**
- Create: `Sources/SimControlApp/AppModel.swift`
- Modify: `Sources/SimControlApp/SimControlApp.swift`
- Create: `Tests/SimControlCoreTests/InventoryFilterTests.swift`

- [ ] **Step 1: Add filter behavior test in core**

Create `Tests/SimControlCoreTests/InventoryFilterTests.swift`:

```swift
import Testing
import SimControlCore

@Test func filtersDevicesByPlatformRuntimeAndState() {
    let device = SimulatorDevice(
        id: "DEVICE-1",
        name: "iPhone",
        udid: "DEVICE-1",
        platform: .iOS,
        runtimeIdentifier: "runtime-ios",
        runtimeVersion: "18.4",
        deviceTypeIdentifier: "type",
        deviceTypeName: "iPhone",
        state: .booted,
        isAvailable: true,
        availabilityError: nil,
        pairingDescription: nil
    )

    let filter = InventoryFilter(platform: .iOS, runtimeIdentifier: "runtime-ios", state: .booted)

    #expect(filter.includes(device))
}
```

- [ ] **Step 2: Implement filter in core domain file**

Append to `Sources/SimControlCore/Domain/SimulatorModels.swift`:

```swift
public struct InventoryFilter: Sendable, Equatable {
    public var platform: SupportedPlatform?
    public var runtimeIdentifier: String?
    public var state: SimulatorDeviceState?

    public init(platform: SupportedPlatform? = nil, runtimeIdentifier: String? = nil, state: SimulatorDeviceState? = nil) {
        self.platform = platform
        self.runtimeIdentifier = runtimeIdentifier
        self.state = state
    }

    public func includes(_ device: SimulatorDevice) -> Bool {
        if let platform, device.platform != platform { return false }
        if let runtimeIdentifier, device.runtimeIdentifier != runtimeIdentifier { return false }
        if let state, device.state != state { return false }
        return true
    }
}
```

- [ ] **Step 3: Add app model**

Create `Sources/SimControlApp/AppModel.swift`:

```swift
import Foundation
import Observation
import SimControlCore

@MainActor
@Observable
final class AppModel {
    var environmentStatus: EnvironmentStatus?
    var inventory = SimulatorInventory(devices: [], runtimes: [], deviceTypes: [])
    var filter = InventoryFilter()
    var selectedDeviceID: SimulatorDevice.ID?
    var isRefreshing = false
    var lastResultText = ""

    private let diagnostics: EnvironmentDiagnostics
    private let inventoryService: InventoryService

    init(
        diagnostics: EnvironmentDiagnostics = EnvironmentDiagnostics(),
        inventoryService: InventoryService = InventoryService()
    ) {
        self.diagnostics = diagnostics
        self.inventoryService = inventoryService
    }

    var filteredDevices: [SimulatorDevice] {
        inventory.devices.filter(filter.includes)
    }

    var selectedDevice: SimulatorDevice? {
        inventory.devices.first { $0.id == selectedDeviceID }
    }

    func refresh() async {
        isRefreshing = true
        defer { isRefreshing = false }

        let status = await diagnostics.check()
        environmentStatus = status
        guard status.isAvailable else { return }

        do {
            inventory = try await inventoryService.refresh()
        } catch {
            lastResultText = String(describing: error)
        }
    }
}
```

Modify `Sources/SimControlApp/SimControlApp.swift`:

```swift
import SwiftUI

@main
struct SimControlApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(model)
                .task { await model.refresh() }
        }
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test --filter InventoryFilterTests && swift test`

Expected: all tests pass and app target compiles.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlApp Sources/SimControlCore/Domain Tests/SimControlCoreTests/InventoryFilterTests.swift
git commit -m "feat: add app model and inventory filtering"
```

## Task 10: Main SwiftUI Shell

**Files:**
- Create: `Sources/SimControlApp/Views/ContentView.swift`
- Create: `Sources/SimControlApp/Views/DeviceInventoryView.swift`
- Create: `Sources/SimControlApp/Views/DeviceDetailView.swift`
- Create: `Sources/SimControlApp/Views/RuntimeCatalogView.swift`
- Create: `Sources/SimControlApp/Views/ResultPanel.swift`

- [ ] **Step 1: Create main layout**

Create `Sources/SimControlApp/Views/ContentView.swift`:

```swift
import SwiftUI
import SimControlCore

struct ContentView: View {
    @Environment(AppModel.self) private var model
    @Environment(\.scenePhase) private var scenePhase

    var body: some View {
        NavigationSplitView {
            RuntimeCatalogView()
                .navigationSplitViewColumnWidth(min: 180, ideal: 220)
        } content: {
            DeviceInventoryView()
                .navigationSplitViewColumnWidth(min: 420, ideal: 620)
        } detail: {
            DeviceDetailView()
                .navigationSplitViewColumnWidth(min: 280, ideal: 360)
        }
        .toolbar {
            ToolbarItemGroup {
                Button("Refresh", systemImage: "arrow.clockwise") {
                    Task { await model.refresh() }
                }
                .disabled(model.isRefreshing)
                Text(model.environmentStatus?.activeXcodePath ?? "No Active Xcode")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .onChange(of: scenePhase) {
            if scenePhase == .active {
                Task { await model.refresh() }
            }
        }
        .frame(minWidth: 900, minHeight: 600)
    }
}
```

- [ ] **Step 2: Create inventory table**

Create `Sources/SimControlApp/Views/DeviceInventoryView.swift`:

```swift
import SwiftUI
import SimControlCore

struct DeviceInventoryView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        @Bindable var model = model

        VStack(spacing: 0) {
            Table(model.filteredDevices, selection: $model.selectedDeviceID) {
                TableColumn("Name", value: \.name)
                TableColumn("Platform") { Text($0.platform.rawValue) }
                TableColumn("Runtime", value: \.runtimeVersion)
                TableColumn("State") { Text($0.state.rawValue) }
                TableColumn("UDID", value: \.udid)
            }
        }
        .navigationTitle("Devices")
    }
}
```

- [ ] **Step 3: Create detail and runtime views**

Create `Sources/SimControlApp/Views/DeviceDetailView.swift`:

```swift
import SwiftUI
import SimControlCore

struct DeviceDetailView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if let device = model.selectedDevice {
                Text(device.name).font(.title2)
                LabeledContent("UDID", value: device.udid)
                LabeledContent("Runtime", value: device.runtimeVersion)
                LabeledContent("State", value: device.state.rawValue)
                if let pairing = device.pairingDescription {
                    LabeledContent("Pairing", value: pairing)
                }
                Divider()
                Text("Target App").font(.headline)
                Text(device.state == .booted ? "Install and launch are available." : "Boot the device to install or launch a Target App.")
                    .foregroundStyle(.secondary)
            } else {
                ContentUnavailableView("Select a Device", systemImage: "iphone", description: Text("Choose a simulator device from the inventory."))
            }
            Spacer()
        }
        .padding()
    }
}
```

Create `Sources/SimControlApp/Views/RuntimeCatalogView.swift`:

```swift
import SwiftUI
import SimControlCore

struct RuntimeCatalogView: View {
    @Environment(AppModel.self) private var model

    var body: some View {
        List(model.inventory.runtimes) { runtime in
            Button {
                model.filter.runtimeIdentifier = runtime.identifier
            } label: {
                VStack(alignment: .leading) {
                    Text(runtime.name)
                    Text("\(runtime.platform.rawValue) · \(runtime.deviceCount) devices")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .buttonStyle(.plain)
        }
        .navigationTitle("Runtimes")
    }
}
```

Create `Sources/SimControlApp/Views/ResultPanel.swift`:

```swift
import SwiftUI

struct ResultPanel: View {
    let text: String

    var body: some View {
        ScrollView {
            Text(text.isEmpty ? "No result output." : text)
                .font(.system(.caption, design: .monospaced))
                .textSelection(.enabled)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding()
        }
    }
}
```

- [ ] **Step 4: Verify**

Run: `swift test`

Expected: all tests pass and SwiftUI target compiles.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlApp/Views
git commit -m "feat: add main SwiftUI shell"
```

## Task 11: Wire Device Actions, Confirmation, and Results

**Files:**
- Modify: `Sources/SimControlApp/AppModel.swift`
- Modify: `Sources/SimControlApp/Views/DeviceDetailView.swift`
- Modify: `Sources/SimControlApp/Views/ResultPanel.swift`

- [ ] **Step 1: Extend app model with operations**

Add these properties and methods to `AppModel`:

```swift
private let deviceOperations = DeviceOperationService()
private var runningDeviceIDs: Set<SimulatorDevice.ID> = []

func isRunning(device: SimulatorDevice) -> Bool {
    runningDeviceIDs.contains(device.id)
}

func bootSelectedDevice() async {
    guard let device = selectedDevice else { return }
    await runDeviceOperation(device: device, commandName: "boot") {
        try await deviceOperations.boot(device: device)
    }
}

func shutdownSelectedDevice() async {
    guard let device = selectedDevice else { return }
    await runDeviceOperation(device: device, commandName: "shutdown") {
        try await deviceOperations.shutdown(device: device)
    }
}

func openSelectedDeviceInSimulator() async {
    guard let device = selectedDevice else { return }
    await runDeviceOperation(device: device, commandName: "open") {
        try await deviceOperations.openInSimulator(device: device)
    }
}

func eraseSelectedDevice() async {
    guard let device = selectedDevice else { return }
    await runDeviceOperation(device: device, commandName: "erase") {
        try await deviceOperations.erase(device: device)
    }
}

func deleteSelectedDevice() async {
    guard let device = selectedDevice else { return }
    runningDeviceIDs.insert(device.id)
    defer { runningDeviceIDs.remove(device.id) }
    do {
        let results = try await deviceOperations.delete(device: device)
        lastResultText = results.map { $0.stderrText + $0.stdoutText }.joined(separator: "\n")
        await refresh()
    } catch {
        lastResultText = String(describing: error)
    }
}

private func runDeviceOperation(device: SimulatorDevice, commandName: String, operation: () async throws -> CommandResult) async {
    runningDeviceIDs.insert(device.id)
    defer { runningDeviceIDs.remove(device.id) }
    do {
        let result = try await operation()
        lastResultText = result.stderrText.isEmpty ? result.stdoutText : result.stderrText
        await refresh()
    } catch {
        lastResultText = "\(commandName) failed for \(device.name) (\(device.udid))\n\(error)"
    }
}
```

- [ ] **Step 2: Replace detail view actions**

Update `DeviceDetailView` action area with:

```swift
let allowed = DeviceOperationPolicy.allowedOperations(for: device)
let running = model.isRunning(device: device)

HStack {
    Button("Boot", systemImage: "play.fill") {
        Task { await model.bootSelectedDevice() }
    }
    .disabled(running || !allowed.contains(.boot))

    Button("Shutdown", systemImage: "stop.fill") {
        Task { await model.shutdownSelectedDevice() }
    }
    .disabled(running || !allowed.contains(.shutdown))

    Button("Open", systemImage: "rectangle.on.rectangle") {
        Task { await model.openSelectedDeviceInSimulator() }
    }
    .disabled(running || !allowed.contains(.openInSimulator))
}

HStack {
    Button("Erase", systemImage: "eraser", role: .destructive) {
        confirmErase = true
    }
    .disabled(running || !allowed.contains(.erase))

    Button("Delete", systemImage: "trash", role: .destructive) {
        confirmDelete = true
    }
    .disabled(running || !allowed.contains(.delete))
}
```

Add private state at the top of `DeviceDetailView`:

```swift
@State private var confirmErase = false
@State private var confirmDelete = false
```

Add confirmation dialogs:

```swift
.confirmationDialog("Erase Device?", isPresented: $confirmErase) {
    Button("Erase", role: .destructive) {
        Task { await model.eraseSelectedDevice() }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("This will erase the selected simulator device contents.")
}
.confirmationDialog("Delete Device?", isPresented: $confirmDelete) {
    Button("Delete", role: .destructive) {
        Task { await model.deleteSelectedDevice() }
    }
    Button("Cancel", role: .cancel) {}
} message: {
    Text("If the simulator is booted, SimControl will shut it down before deleting it.")
}
```

- [ ] **Step 3: Show result output**

Render `ResultPanel(text: model.lastResultText)` at the bottom of `DeviceDetailView`.

- [ ] **Step 4: Verify**

Run: `swift test`

Expected: all tests pass and the app target compiles with modern `.confirmationDialog`.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlApp
git commit -m "feat: wire device actions"
```

## Task 12: Create Device Flow and Runtime Entry Point

**Files:**
- Create: `Sources/SimControlApp/Views/CreateDeviceSheet.swift`
- Modify: `Sources/SimControlApp/AppModel.swift`
- Modify: `Sources/SimControlApp/Views/ContentView.swift`
- Modify: `Sources/SimControlApp/Views/RuntimeCatalogView.swift`

- [ ] **Step 1: Add creation state and method**

Add to `AppModel`:

```swift
var showingCreateDevice = false
var preselectedRuntimeIdentifier: String?

func openCreateDevice(runtimeIdentifier: String? = nil) {
    preselectedRuntimeIdentifier = runtimeIdentifier
    showingCreateDevice = true
}

func createDevice(name: String, deviceTypeIdentifier: String, runtimeIdentifier: String) async {
    do {
        let result = try await deviceOperations.create(
            name: name,
            deviceTypeIdentifier: deviceTypeIdentifier,
            runtimeIdentifier: runtimeIdentifier
        )
        lastResultText = result.stderrText.isEmpty ? result.stdoutText : result.stderrText
        await refresh()
    } catch {
        lastResultText = "create failed\n\(error)"
    }
}
```

- [ ] **Step 2: Add create sheet**

Create `Sources/SimControlApp/Views/CreateDeviceSheet.swift`:

```swift
import SwiftUI
import SimControlCore

struct CreateDeviceSheet: View {
    @Environment(AppModel.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var runtimeIdentifier = ""
    @State private var deviceTypeIdentifier = ""
    @State private var name = ""

    var body: some View {
        Form {
            Picker("Runtime", selection: $runtimeIdentifier) {
                ForEach(model.inventory.runtimes.filter { $0.platform != .other }) { runtime in
                    Text(runtime.name).tag(runtime.identifier)
                }
            }

            Picker("Device Type", selection: $deviceTypeIdentifier) {
                ForEach(compatibleDeviceTypes) { type in
                    Text(type.name).tag(type.identifier)
                }
            }

            TextField("Name", text: $name)
        }
        .padding()
        .frame(width: 420)
        .onAppear {
            runtimeIdentifier = model.preselectedRuntimeIdentifier ?? model.inventory.runtimes.first { $0.platform != .other }?.identifier ?? ""
            deviceTypeIdentifier = compatibleDeviceTypes.first?.identifier ?? ""
            updateDefaultName()
        }
        .onChange(of: runtimeIdentifier) { updateDefaultName() }
        .onChange(of: deviceTypeIdentifier) { updateDefaultName() }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button("Create") {
                    Task {
                        await model.createDevice(name: name, deviceTypeIdentifier: deviceTypeIdentifier, runtimeIdentifier: runtimeIdentifier)
                        dismiss()
                    }
                }
                .disabled(name.isEmpty || runtimeIdentifier.isEmpty || deviceTypeIdentifier.isEmpty)
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
        }
    }

    private var compatibleDeviceTypes: [DeviceType] {
        guard let runtime = model.inventory.runtimes.first(where: { $0.identifier == runtimeIdentifier }) else {
            return []
        }
        return model.inventory.deviceTypes.filter { $0.supportedPlatforms.contains(runtime.platform) }
    }

    private func updateDefaultName() {
        guard let runtime = model.inventory.runtimes.first(where: { $0.identifier == runtimeIdentifier }),
              let deviceType = model.inventory.deviceTypes.first(where: { $0.identifier == deviceTypeIdentifier }) else {
            return
        }
        let base = DeviceNameGenerator.defaultName(deviceTypeName: deviceType.name, runtimeName: runtime.name)
        name = DeviceNameGenerator.uniqueName(baseName: base, existingNames: Set(model.inventory.devices.map(\.name)))
    }
}
```

- [ ] **Step 3: Add toolbar and runtime entry**

Add to `ContentView` toolbar:

```swift
Button("New Device", systemImage: "plus") {
    model.openCreateDevice()
}
```

Add to `ContentView`:

```swift
.sheet(isPresented: Bindable(model).showingCreateDevice) {
    CreateDeviceSheet()
}
```

In `RuntimeCatalogView`, add a context button for each runtime:

```swift
Button("New Device") {
    model.openCreateDevice(runtimeIdentifier: runtime.identifier)
}
.disabled(runtime.platform == .other)
```

- [ ] **Step 4: Verify**

Run: `swift test`

Expected: tests pass and create flow compiles.

- [ ] **Step 5: Commit**

```bash
git add Sources/SimControlApp
git commit -m "feat: add device creation flow"
```

## Task 13: Target App Picker, Install, and Launch UI

**Files:**
- Modify: `Sources/SimControlApp/AppModel.swift`
- Modify: `Sources/SimControlApp/Views/DeviceDetailView.swift`

- [ ] **Step 1: Add app bundle state and methods**

Add to `AppModel`:

```swift
var selectedTargetAppBundle: TargetAppBundle?

func installTargetApp(on devices: [SimulatorDevice]) async {
    guard let selectedTargetAppBundle else { return }
    var outputs: [String] = []
    for device in devices where TargetAppPolicy.canInstallOrLaunch(deviceState: device.state) {
        do {
            let result = try await TargetAppService().install(bundle: selectedTargetAppBundle, on: device)
            outputs.append("\(device.name): \(result.stderrText.isEmpty ? "installed" : result.stderrText)")
        } catch {
            outputs.append("\(device.name): \(error)")
        }
    }
    lastResultText = outputs.joined(separator: "\n")
    await refresh()
}

func launchTargetAppOnSelectedDevice() async {
    guard let selectedTargetAppBundle, let selectedDevice else { return }
    do {
        let result = try await TargetAppService().launch(bundle: selectedTargetAppBundle, on: selectedDevice)
        lastResultText = result.stderrText.isEmpty ? result.stdoutText : result.stderrText
        await refresh()
    } catch {
        lastResultText = "launch failed for \(selectedDevice.name) (\(selectedDevice.udid))\n\(error)"
    }
}
```

- [ ] **Step 2: Add file importer and controls**

In `DeviceDetailView`, add:

```swift
@State private var showingAppImporter = false
```

Add Target App controls:

```swift
Button("Choose .app", systemImage: "app.badge") {
    showingAppImporter = true
}
.fileImporter(isPresented: $showingAppImporter, allowedContentTypes: [.applicationBundle]) { result in
    if case let .success(url) = result {
        model.selectedTargetAppBundle = TargetAppBundle(url: url)
    }
}

Button("Install", systemImage: "square.and.arrow.down") {
    if let device = model.selectedDevice {
        Task { await model.installTargetApp(on: [device]) }
    }
}
.disabled(device.state != .booted || model.selectedTargetAppBundle == nil)

Button("Launch", systemImage: "play.rectangle") {
    Task { await model.launchTargetAppOnSelectedDevice() }
}
.disabled(device.state != .booted || model.selectedTargetAppBundle == nil)
```

- [ ] **Step 3: Verify**

Run: `swift test`

Expected: tests pass and Target App controls compile.

- [ ] **Step 4: Commit**

```bash
git add Sources/SimControlApp
git commit -m "feat: add target app install and launch UI"
```

## Task 14: Manual Acceptance Verification

**Files:**
- Modify: `README.md`

- [ ] **Step 1: Add run and verification instructions**

Replace `README.md` with:

```md
# Xcode Simulator Control

SimControl is a macOS SwiftUI app for inspecting and operating simulator devices from the Active Xcode using `xcrun simctl`.

## Development

```bash
swift test
swift run SimControlApp
```

## MVP Manual Checks

- App shows the Active Xcode path.
- App shows an environment problem state when `xcrun simctl list --json` is unavailable.
- Device inventory lists name, UDID, platform, runtime version, device type, state, and availability problems.
- Runtime catalog shows installed runtimes and device counts.
- Device creation proposes a collision-safe name.
- Boot, shutdown, open, erase, and delete actions refresh inventory after completion.
- Erase and delete require confirmation.
- Target App install and launch controls are disabled unless the selected device is Booted.
- `.app` bundle install supports one or more Booted devices.
- Target App launch supports a single selected Booted device.
- Window size and split position are the only persisted user state.
```

- [ ] **Step 2: Run full automated verification**

Run: `swift test`

Expected: all tests pass.

- [ ] **Step 3: Run app for smoke verification**

Run: `swift run SimControlApp`

Expected: a macOS window opens, the Active Xcode path appears, and the app either displays the device inventory or the environment diagnostic state.

- [ ] **Step 4: Compare against acceptance criteria**

Read `docs/FUNCTIONAL_SPEC.md` sections 14-16 and check each implemented behavior. Record any missing behavior as a new follow-up issue or task before declaring the MVP complete.

- [ ] **Step 5: Commit**

```bash
git add README.md
git commit -m "docs: add development and MVP verification notes"
```

## Self-Review Checklist

- Spec coverage: tasks cover environment diagnostics, inventory, runtime catalog, device creation, device operations, Target App install/launch, persistence, backend choice, and explicit exclusions.
- Marker scan: no unfinished-work markers remain in the executable steps.
- Type consistency: `SimulatorDevice`, `SimulatorRuntime`, `DeviceType`, `InventoryFilter`, `SimctlClient`, `DeviceOperationService`, and `TargetAppService` names are used consistently across tasks.
- Testing strategy: core behavior is covered by Swift Testing; UI wiring is verified through app target compilation and final smoke testing.
- Excluded scope: runtime acquisition, logs, menu bar control, Xcode switching, pairing mutation, and app build/archive inputs are not implemented by this plan.
