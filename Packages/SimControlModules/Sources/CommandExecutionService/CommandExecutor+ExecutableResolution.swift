import Foundation

extension CommandExecutor {
  private static let fallbackExecutableSearchDirectories = [
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin"
  ]

  func executableURL(for executable: String) -> URL {
    if executable.contains("/") {
      return URL(fileURLWithPath: executable)
    }

    if let resolvedPath = resolvedExecutablePath(for: executable) {
      return URL(fileURLWithPath: resolvedPath)
    }

    return URL(fileURLWithPath: executable)
  }

  private func resolvedExecutablePath(for executable: String) -> String? {
    let searchPath = ProcessInfo.processInfo.environment["PATH"] ?? ""

    for directory in executableSearchDirectories(from: searchPath) {
      let candidate = "\(directory)/\(executable)"
      if FileManager.default.isExecutableFile(atPath: candidate) {
        return candidate
      }
    }

    return nil
  }

  private func executableSearchDirectories(from searchPath: String) -> [String] {
    var directories: [String] = []
    var seenDirectories = Set<String>()

    func append(_ directory: String) {
      guard !directory.isEmpty, seenDirectories.insert(directory).inserted else {
        return
      }

      directories.append(directory)
    }

    for directory in searchPath.split(separator: ":") {
      append(String(directory))
    }

    for directory in Self.fallbackExecutableSearchDirectories {
      append(directory)
    }

    return directories
  }
}
