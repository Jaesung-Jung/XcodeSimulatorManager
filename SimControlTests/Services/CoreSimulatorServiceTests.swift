import Foundation
import Testing
@testable import SimControl

@Suite
struct CoreSimulatorServiceTests {
  @Test func selectedXcodePathRunsXcrunCommandAndTrimsOutput() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["xcode-select", "-p"],
      stdout: "/Applications/Xcode.app/Contents/Developer\n"
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.selectedXcodePath()

    #expect(result.succeeded)
    #expect(result.developerPath == URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"))
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == nil)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["xcode-select", "-p"],
        timeout: 10
      )
    ])
  }

  @Test func selectedXcodePathFailurePreservesCommandResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["xcode-select", "-p"],
      stderr: "xcode-select failed",
      exitCode: 72
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.selectedXcodePath()

    #expect(!result.succeeded)
    #expect(result.developerPath == nil)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == "xcrun xcode-select -p failed with exit code 72.")
  }

  @Test func listRunsSimctlListCommandAndDecodesPayload() async throws {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: """
      {
        "runtimes": [
          {
            "identifier": "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
            "name": "iOS 26.4",
            "version": "26.4",
            "buildversion": "23E244",
            "platform": "iOS",
            "isAvailable": true
          }
        ],
        "devicetypes": [],
        "devices": {},
        "pairs": {}
      }
      """
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.list()

    #expect(result.succeeded)
    let payload = try #require(result.payload)
    #expect(payload.runtimes.first?.identifier == "com.apple.CoreSimulator.SimRuntime.iOS-26-4")
    #expect(payload.deviceTypes.isEmpty)
    #expect(payload.devicesByRuntimeID.isEmpty)
    #expect(payload.pairsByID.isEmpty)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == nil)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "list", "-j"],
        timeout: 30
      )
    ])
  }

  @Test func listFailureDoesNotDecodeAndPreservesCommandResult() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "not json",
      stderr: "simctl failed",
      exitCode: 65
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.list()

    #expect(!result.succeeded)
    #expect(result.payload == nil)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic == "xcrun simctl list -j failed with exit code 65.")
  }

  @Test func listInvalidJSONPreservesSuccessfulCommandResultAndDiagnostic() async {
    let commandResult = makeCommandResult(
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "not json"
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.list()

    #expect(!result.succeeded)
    #expect(result.payload == nil)
    #expect(result.commandResult == commandResult)
    #expect(result.diagnostic?.contains("Failed to decode simctl list JSON") == true)
  }

  @Test func openSimulatorAppRunsOpenCommandAndReturnsResult() async {
    let commandResult = makeCommandResult(
      executable: "/usr/bin/open",
      arguments: ["-a", "Simulator"]
    )
    let recorder = CommandRecorder(results: [commandResult])
    let service = makeService(recorder: recorder)

    let result = await service.openSimulatorApp()

    #expect(result == commandResult)
    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "/usr/bin/open",
        arguments: ["-a", "Simulator"],
        timeout: 10
      )
    ])
  }

  @Test func customTimeoutsAreForwardedToCommands() async {
    let recorder = CommandRecorder(results: [
      makeCommandResult(executable: "xcrun", arguments: ["xcode-select", "-p"]),
      makeCommandResult(executable: "xcrun", arguments: ["simctl", "list", "-j"]),
      makeCommandResult(executable: "/usr/bin/open", arguments: ["-a", "Simulator"])
    ])
    let service = makeService(
      recorder: recorder,
      selectedXcodePathTimeout: 1,
      listTimeout: 2,
      openSimulatorAppTimeout: 3
    )

    _ = await service.selectedXcodePath()
    _ = await service.list()
    _ = await service.openSimulatorApp()

    #expect(await recorder.recordedCalls() == [
      CommandCall(
        executable: "xcrun",
        arguments: ["xcode-select", "-p"],
        timeout: 1
      ),
      CommandCall(
        executable: "xcrun",
        arguments: ["simctl", "list", "-j"],
        timeout: 2
      ),
      CommandCall(
        executable: "/usr/bin/open",
        arguments: ["-a", "Simulator"],
        timeout: 3
      )
    ])
  }

  private func makeService(recorder: CommandRecorder) -> CoreSimulatorService {
    CoreSimulatorService { executable, arguments, timeout in
      await recorder.run(executable, arguments, timeout)
    }
  }

  private func makeService(
    recorder: CommandRecorder,
    selectedXcodePathTimeout: TimeInterval?,
    listTimeout: TimeInterval?,
    openSimulatorAppTimeout: TimeInterval?
  ) -> CoreSimulatorService {
    CoreSimulatorService(
      selectedXcodePathTimeout: selectedXcodePathTimeout,
      listTimeout: listTimeout,
      openSimulatorAppTimeout: openSimulatorAppTimeout
    ) { executable, arguments, timeout in
      await recorder.run(executable, arguments, timeout)
    }
  }

  private func makeCommandResult(
    executable: String,
    arguments: [String],
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

private struct CommandCall: Equatable {
  let executable: String
  let arguments: [String]
  let timeout: TimeInterval?
}

private actor CommandRecorder {
  private var results: [CommandResult]
  private var calls: [CommandCall] = []

  init(results: [CommandResult]) {
    self.results = results
  }

  func run(
    _ executable: String,
    _ arguments: [String],
    _ timeout: TimeInterval?
  ) -> CommandResult {
    calls.append(
      CommandCall(
        executable: executable,
        arguments: arguments,
        timeout: timeout
      )
    )

    guard !results.isEmpty else {
      return CommandResult(
        id: "missing-command-result",
        executable: executable,
        arguments: arguments,
        stdout: "",
        stderr: "No test command result was provided.",
        exitCode: -1,
        duration: 0,
        startedAt: Date(timeIntervalSince1970: 100)
      )
    }

    return results.removeFirst()
  }

  func recordedCalls() -> [CommandCall] {
    calls
  }
}
