import Foundation
import SimControlDomain

extension CommandExecutor {
  func makeResult(
    id: String,
    executable: String,
    arguments: [String],
    stdoutData: Data,
    stderrData: Data,
    fallbackStderr: String?,
    stderrSuffix: String? = nil,
    exitCode: Int32,
    startedAt: Date
  ) -> CommandResult {
    var stderr = decodedString(from: stderrData)

    if stderr.isEmpty, let fallbackStderr {
      stderr = fallbackStderr
    }

    if let stderrSuffix {
      stderr = [stderr, stderrSuffix]
        .filter { !$0.isEmpty }
        .joined(separator: "\n")
    }

    return CommandResult(
      id: id,
      executable: executable,
      arguments: arguments,
      stdout: decodedString(from: stdoutData),
      stderr: stderr,
      exitCode: exitCode,
      duration: Date().timeIntervalSince(startedAt),
      startedAt: startedAt
    )
  }

  func decodedString(from data: Data) -> String {
    String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
  }

  func formatTimeout(_ timeout: TimeInterval?) -> String {
    guard let timeout else {
      return "0"
    }

    return String(format: "%.2f", timeout)
  }
}
