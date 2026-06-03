import Foundation
import SimControlDomain

extension CoreSimulatorService {
  func commandFailureDiagnostic(command: String, result: CommandResult) -> String {
    let summary = "\(command) failed with exit code \(result.exitCode)."
    let stderr = result.stderr.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !stderr.isEmpty else {
      return summary
    }

    return "\(summary)\n\(stderr)"
  }

  func commandResult(
    arguments: [String],
    stdout: String,
    stderr: String,
    exitCode: Int32,
    startedAt: Date
  ) -> CommandResult {
    CommandResult(
      id: "core-simulator-service-\(makeID())",
      executable: "xcrun",
      arguments: arguments,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      duration: max(0, now().timeIntervalSince(startedAt)),
      startedAt: startedAt
    )
  }

  @usableFromInline static func defaultPushPayloadURL() -> URL {
    FileManager.default.temporaryDirectory
      .appendingPathComponent("SimControl-PushPayload-\(UUID().uuidString).json")
  }

  @usableFromInline static func defaultWritePushPayload(_ payloadJSON: String, to url: URL) throws {
    try payloadJSON.write(to: url, atomically: true, encoding: .utf8)
  }

  @usableFromInline static func defaultRemovePushPayload(_ url: URL) {
    try? FileManager.default.removeItem(at: url)
  }
}
