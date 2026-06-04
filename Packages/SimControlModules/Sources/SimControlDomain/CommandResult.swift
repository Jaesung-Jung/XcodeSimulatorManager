import Foundation

/// The captured output and timing for a process executed by SimControl.
///
/// `CommandResult` is intentionally a plain value type so command execution can
/// remain isolated in the service layer while stores and views can still render
/// command diagnostics such as stderr, exit code, and elapsed time.
public struct CommandResult: Identifiable, Equatable, Hashable {
  /// A stable identifier for the command result.
  public let id: String

  /// The executable path or launch name that was invoked.
  public let executable: String

  /// The arguments passed to the executable.
  public let arguments: [String]

  /// The captured standard output.
  public let stdout: String

  /// The captured standard error.
  public let stderr: String

  /// The process exit code returned by the operating system.
  public let exitCode: Int32

  /// The elapsed execution time in seconds.
  public let duration: TimeInterval

  /// The time at which command execution started.
  public let startedAt: Date

  /// Creates a captured command result value.
  public init(
    id: String,
    executable: String,
    arguments: [String],
    stdout: String,
    stderr: String,
    exitCode: Int32,
    duration: TimeInterval,
    startedAt: Date
  ) {
    self.id = id
    self.executable = executable
    self.arguments = arguments
    self.stdout = stdout
    self.stderr = stderr
    self.exitCode = exitCode
    self.duration = duration
    self.startedAt = startedAt
  }

  /// Indicates whether the command completed with a zero exit code.
  public var succeeded: Bool {
    exitCode == 0
  }
}
