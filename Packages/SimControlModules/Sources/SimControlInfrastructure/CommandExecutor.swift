import Foundation
import SimControlDomain
import Darwin

/// Runs external commands and captures their complete result.
public struct CommandExecutor {
  private static let fallbackExecutableSearchDirectories = [
    "/usr/bin",
    "/bin",
    "/usr/sbin",
    "/sbin"
  ]

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

  private func executableURL(for executable: String) -> URL {
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

  private func closePipes(stdoutPipe: Pipe, stderrPipe: Pipe) {
    try? stdoutPipe.fileHandleForWriting.close()
    try? stderrPipe.fileHandleForWriting.close()
  }

  private func makeResult(
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

  private func decodedString(from data: Data) -> String {
    String(data: data, encoding: .utf8) ?? String(decoding: data, as: UTF8.self)
  }

  private func formatTimeout(_ timeout: TimeInterval?) -> String {
    guard let timeout else {
      return "0"
    }

    return String(format: "%.2f", timeout)
  }
}

private actor PipeDrain {
  private let handle: FileHandle
  private let stream: AsyncStream<Data>
  private let continuation: AsyncStream<Data>.Continuation

  init(pipe: Pipe) {
    handle = pipe.fileHandleForReading
    let streamPair = AsyncStream<Data>.makeStream()
    stream = streamPair.stream
    continuation = streamPair.continuation
  }

  func start() {
    let continuation = continuation
    handle.readabilityHandler = { handle in
      let availableData = handle.availableData

      if availableData.isEmpty {
        handle.readabilityHandler = nil
        continuation.finish()
        return
      }

      continuation.yield(availableData)
    }
  }

  func waitForData() async -> Data {
    var output = Data()
    for await chunk in stream {
      output.append(chunk)
    }
    return output
  }
}

private actor ProcessTerminationObserver {
  private var continuation: CheckedContinuation<Void, Never>?
  private var hasTerminated = false

  func install(on process: Process) {
    process.terminationHandler = { [weak self] _ in
      Task {
        await self?.resume()
      }
    }
  }

  func wait() async {
    if hasTerminated {
      return
    }

    await withCheckedContinuation { continuation in
      if hasTerminated {
        continuation.resume()
      } else {
        self.continuation = continuation
      }
    }
  }

  private func resume() {
    guard !hasTerminated else {
      return
    }

    hasTerminated = true
    let continuation = continuation
    self.continuation = nil
    continuation?.resume()
  }
}

private actor CommandTimeoutController {
  private static let hardKillGracePeriod: TimeInterval = 0.25

  private let process: Process
  private var didTimeOut = false
  private var didForceKill = false

  var timedOut: Bool {
    didTimeOut
  }

  var wasForceKilled: Bool {
    didForceKill
  }

  init(process: Process) {
    self.process = process
  }

  func start(timeout: TimeInterval?) -> Task<Void, Never>? {
    guard let timeout else {
      return nil
    }

    return Task { [weak self] in
      let nanoseconds = UInt64(max(0, timeout) * 1_000_000_000)
      try? await Task.sleep(nanoseconds: nanoseconds)

      guard !Task.isCancelled else {
        return
      }

      await self?.terminateProcessIfRunning()
      try? await Task.sleep(
        nanoseconds: UInt64(Self.hardKillGracePeriod * 1_000_000_000)
      )

      guard !Task.isCancelled else {
        return
      }

      await self?.forceKillProcessIfRunning()
    }
  }

  private func terminateProcessIfRunning() {
    guard process.isRunning else {
      return
    }

    didTimeOut = true
    process.terminate()
  }

  private func forceKillProcessIfRunning() {
    guard process.isRunning else {
      return
    }

    if Darwin.kill(process.processIdentifier, SIGKILL) == 0 {
      didForceKill = true
    }
  }
}
