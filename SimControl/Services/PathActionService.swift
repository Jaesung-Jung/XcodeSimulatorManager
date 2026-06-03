import AppKit
import SimControlDomain
import Foundation

/// Performs user-visible filesystem path actions such as opening Finder and copying paths.
struct PathActionService {
  private let fileExists: (URL) -> Bool
  private let isReadable: (URL) -> Bool
  private let openURL: @MainActor (URL) -> Bool
  private let copyString: @MainActor (String) -> Bool
  private let now: () -> Date
  private let makeID: () -> String

  init(
    fileManager: FileManager = .default,
    fileExists: ((URL) -> Bool)? = nil,
    isReadable: ((URL) -> Bool)? = nil,
    openURL: @escaping @MainActor (URL) -> Bool = { url in
      NSWorkspace.shared.open(url)
    },
    copyString: @escaping @MainActor (String) -> Bool = { value in
      let pasteboard = NSPasteboard.general
      pasteboard.clearContents()
      return pasteboard.setString(value, forType: .string)
    },
    now: @escaping () -> Date = Date.init,
    makeID: @escaping () -> String = { UUID().uuidString }
  ) {
    self.fileExists = fileExists ?? { url in
      fileManager.fileExists(atPath: url.path)
    }
    self.isReadable = isReadable ?? { url in
      fileManager.isReadableFile(atPath: url.path)
    }
    self.openURL = openURL
    self.copyString = copyString
    self.now = now
    self.makeID = makeID
  }

  func openInFinder(_ url: URL?, label: String) async -> CommandResult {
    let startedAt = now()
    let arguments = ["open-finder", url?.path ?? label]

    guard let url else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "No \(label) path is available.",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    guard fileExists(url) else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "\(label) path does not exist: \(url.path)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    guard isReadable(url) else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Permission denied for \(label) path: \(url.path)",
        exitCode: 13,
        startedAt: startedAt
      )
    }

    let opened = await openURL(url)
    guard opened else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "Finder could not open \(label) path: \(url.path)",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    return commandResult(
      arguments: arguments,
      stdout: "Opened \(label) path: \(url.path)",
      stderr: "",
      exitCode: 0,
      startedAt: startedAt
    )
  }

  func copy(_ value: String?, label: String) async -> CommandResult {
    let startedAt = now()
    let arguments = ["copy", value ?? label]

    guard let value, !value.isEmpty else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "No \(label) is available.",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    let copied = await copyString(value)
    guard copied else {
      return commandResult(
        arguments: arguments,
        stdout: "",
        stderr: "\(label) could not be copied to the clipboard.",
        exitCode: 1,
        startedAt: startedAt
      )
    }

    return commandResult(
      arguments: arguments,
      stdout: "Copied \(label).",
      stderr: "",
      exitCode: 0,
      startedAt: startedAt
    )
  }

  func copyPath(_ url: URL?, label: String) async -> CommandResult {
    await copy(url?.path, label: "\(label) path")
  }

  private func commandResult(
    arguments: [String],
    stdout: String,
    stderr: String,
    exitCode: Int32,
    startedAt: Date
  ) -> CommandResult {
    CommandResult(
      id: "path-action-\(makeID())",
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
