import Foundation
import SimControlDomain

/// Runs external commands and captures their complete result.
public struct CommandExecutor {
  /// Creates a command executor.
  public init() {}

  /// Executes a command asynchronously and returns a non-throwing result value.
  public func execute(
    executable: String,
    arguments: [String] = [],
    timeout: TimeInterval? = nil
  ) async -> CommandResult {
    let id = UUID().uuidString
    let startedAt = Date()
    let process = Process()
    let stdoutPipe = Pipe()
    let stderrPipe = Pipe()
    let stdoutDrain = PipeDrain(pipe: stdoutPipe)
    let stderrDrain = PipeDrain(pipe: stderrPipe)

    process.executableURL = executableURL(for: executable)
    process.arguments = arguments
    process.standardOutput = stdoutPipe
    process.standardError = stderrPipe
    let terminationObserver = ProcessTerminationObserver()
    await terminationObserver.install(on: process)
    await stdoutDrain.start()
    await stderrDrain.start()

    do {
      try process.run()
    } catch {
      closePipes(stdoutPipe: stdoutPipe, stderrPipe: stderrPipe)
      let stdoutData = await stdoutDrain.waitForData()
      let stderrData = await stderrDrain.waitForData()

      return makeResult(
        id: id,
        executable: executable,
        arguments: arguments,
        stdoutData: stdoutData,
        stderrData: stderrData,
        fallbackStderr: error.localizedDescription,
        exitCode: -1,
        startedAt: startedAt
      )
    }

    let timeoutController = CommandTimeoutController(process: process)
    let timeoutTask = await timeoutController.start(timeout: timeout)
    await terminationObserver.wait()
    timeoutTask?.cancel()
    let timedOut = await timeoutController.timedOut

    var stderrSuffix: String?
    if timedOut {
      stderrSuffix = "Command timed out after \(formatTimeout(timeout)) seconds."
      if await timeoutController.wasForceKilled {
        stderrSuffix?.append("\nCommand did not exit after SIGTERM and was force killed.")
      }
    }
    let stdoutData = await stdoutDrain.waitForData()
    let stderrData = await stderrDrain.waitForData()

    return makeResult(
      id: id,
      executable: executable,
      arguments: arguments,
      stdoutData: stdoutData,
      stderrData: stderrData,
      fallbackStderr: nil,
      stderrSuffix: stderrSuffix,
      exitCode: process.terminationStatus,
      startedAt: startedAt
    )
  }
}
