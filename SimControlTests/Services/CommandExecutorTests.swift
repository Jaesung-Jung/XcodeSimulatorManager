import Foundation
import Testing
@testable import SimControl

@Suite
struct CommandExecutorTests {
  @Test func successCommandCapturesOutputAndTiming() async {
    let executor = CommandExecutor()
    let result = await executor.execute(
      executable: "/bin/echo",
      arguments: ["hello"]
    )

    #expect(result.succeeded)
    #expect(result.executable == "/bin/echo")
    #expect(result.arguments == ["hello"])
    #expect(result.stdout == "hello\n")
    #expect(result.stderr == "")
    #expect(result.exitCode == 0)
    #expect(result.duration >= 0)
    #expect(result.startedAt <= Date())
    #expect(!result.id.isEmpty)
  }

  @Test func failureCommandPreservesStderrAndExitCode() async {
    let executor = CommandExecutor()
    let result = await executor.execute(
      executable: "/bin/sh",
      arguments: ["-c", "printf 'problem' >&2; exit 7"]
    )

    #expect(!result.succeeded)
    #expect(result.stdout == "")
    #expect(result.stderr == "problem")
    #expect(result.exitCode == 7)
  }

  @Test func largeStdoutDoesNotBlockPipeDrain() async {
    let executor = CommandExecutor()
    let result = await executor.execute(
      executable: "/bin/sh",
      arguments: ["-c", "i=0; while [ $i -lt 20000 ]; do echo output; i=$((i + 1)); done"]
    )

    #expect(result.succeeded)
    #expect(result.stdout.split(separator: "\n").count == 20000)
    #expect(result.stderr == "")
  }

  @Test func missingExecutableReturnsFailureResult() async {
    let executable = "/no/such/command-executor-fixture"
    let executor = CommandExecutor()
    let result = await executor.execute(executable: executable)

    #expect(!result.succeeded)
    #expect(result.executable == executable)
    #expect(result.arguments == [])
    #expect(result.stdout == "")
    #expect(!result.stderr.isEmpty)
    #expect(result.exitCode == -1)
  }

  @Test func timeoutTerminatesCommandAndRecordsContext() async {
    let executor = CommandExecutor()
    let result = await executor.execute(
      executable: "/bin/sh",
      arguments: ["-c", "sleep 2"],
      timeout: 0.1
    )

    #expect(!result.succeeded)
    #expect(result.stderr.contains("Command timed out after"))
    #expect(result.duration < 2)
  }

  @Test func timeoutForceKillsCommandThatIgnoresTermination() async {
    let executor = CommandExecutor()
    let result = await executor.execute(
      executable: "/bin/sh",
      arguments: ["-c", "trap '' TERM; while :; do :; done"],
      timeout: 0.1
    )

    #expect(!result.succeeded)
    #expect(result.stderr.contains("Command timed out after"))
    #expect(result.stderr.contains("force killed"))
    #expect(result.duration < 2)
  }
}
