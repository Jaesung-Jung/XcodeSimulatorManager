import Foundation

/// The captured output and timing for a process executed by SimControl.
///
/// `CommandResult` is intentionally a plain value type so command execution can
/// remain isolated in the service layer while stores and views can still render
/// command diagnostics such as stderr, exit code, and elapsed time.
struct CommandResult: Identifiable, Equatable, Hashable {
  /// A stable identifier for the command result.
  let id: String

  /// The executable path or launch name that was invoked.
  let executable: String

  /// The arguments passed to the executable.
  let arguments: [String]

  /// The captured standard output.
  let stdout: String

  /// The captured standard error.
  let stderr: String

  /// The process exit code returned by the operating system.
  let exitCode: Int32

  /// The elapsed execution time in seconds.
  let duration: TimeInterval

  /// The time at which command execution started.
  let startedAt: Date

  /// Indicates whether the command completed with a zero exit code.
  var succeeded: Bool {
    exitCode == 0
  }
}
