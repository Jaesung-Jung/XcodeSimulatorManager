import Foundation
import SimControlDomain

/// Clears an installed app's data container without deleting the container root.
public struct AppSandboxResetService {
  private let fileManager: FileManager
  private let now: () -> Date
  private let makeID: () -> String

  /// Creates an app sandbox reset service.
  public init(
    fileManager: FileManager = .default,
    now: @escaping () -> Date = Date.init,
    makeID: @escaping () -> String = { UUID().uuidString }
  ) {
    self.fileManager = fileManager
    self.now = now
    self.makeID = makeID
  }

  /// Removes the contents of an app data container.
  public func resetSandbox(at dataContainer: URL) async -> CommandResult {
    let startedAt = now()
    let arguments = ["reset-sandbox", dataContainer.path]
    var isDirectory: ObjCBool = false

    guard fileManager.fileExists(atPath: dataContainer.path, isDirectory: &isDirectory) else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Sandbox data container does not exist: \(dataContainer.path)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    guard isDirectory.boolValue else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Sandbox data container is not a folder: \(dataContainer.path)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    let contents: [URL]
    do {
      contents = try fileManager.contentsOfDirectory(
        at: dataContainer,
        includingPropertiesForKeys: nil
      )
    } catch {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Sandbox contents could not be read: \(error.localizedDescription)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    var removedCount = 0
    var failures: [String] = []

    for item in contents {
      do {
        try fileManager.removeItem(at: item)
        removedCount += 1
      } catch {
        failures.append("\(item.lastPathComponent): \(error.localizedDescription)")
      }
    }

    let stdout = removedCount == 0
      ? "Sandbox was already empty."
      : "Removed \(removedCount) sandbox item(s)."

    return commandResult(
      arguments: arguments,
      stdout: stdout,
      stderr: failures.joined(separator: "\n"),
      exitCode: failures.isEmpty ? 0 : 1,
      startedAt: startedAt
    )
  }

  private func commandResult(
    arguments: [String],
    stdout: String,
    stderr: String,
    exitCode: Int32,
    startedAt: Date
  ) -> CommandResult {
    CommandResult(
      id: "sandbox-reset-\(makeID())",
      executable: "SimControl",
      arguments: arguments,
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      duration: max(0, now().timeIntervalSince(startedAt)),
      startedAt: startedAt
    )
  }
}
