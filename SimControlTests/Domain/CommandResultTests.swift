import Foundation
import Testing
@testable import SimControl

@MainActor
@Suite
struct CommandResultTests {
  @Test func succeededReflectsExitCode() {
    let success = makeCommandResult(id: "success", exitCode: 0)
    let failure = makeCommandResult(id: "failure", exitCode: 1)

    #expect(success.succeeded)
    #expect(!failure.succeeded)
  }

  @Test func preservesCommandOutputAndTiming() {
    let startedAt = Date(timeIntervalSince1970: 100)
    let result = CommandResult(
      id: "command-1",
      executable: "xcrun",
      arguments: ["simctl", "list", "-j"],
      stdout: "{}",
      stderr: "warning",
      exitCode: 0,
      duration: 0.42,
      startedAt: startedAt
    )

    #expect(result.id == "command-1")
    #expect(result.executable == "xcrun")
    #expect(result.arguments == ["simctl", "list", "-j"])
    #expect(result.stdout == "{}")
    #expect(result.stderr == "warning")
    #expect(result.duration == 0.42)
    #expect(result.startedAt == startedAt)
  }

  private func makeCommandResult(id: String, exitCode: Int32) -> CommandResult {
    CommandResult(
      id: id,
      executable: "true",
      arguments: [],
      stdout: "",
      stderr: "",
      exitCode: exitCode,
      duration: 0.1,
      startedAt: Date(timeIntervalSince1970: 100)
    )
  }
}
