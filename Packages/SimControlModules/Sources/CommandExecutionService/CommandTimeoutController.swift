import Darwin
import Foundation

actor CommandTimeoutController {
  private static let hardKillGracePeriod: TimeInterval = 0.25

  private let process: Process
  private var didTimeOut = false
  private var didForceKill = false

  var timedOut: Bool { didTimeOut }

  var wasForceKilled: Bool { didForceKill }

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
      try? await Task.sleep(nanoseconds: UInt64(Self.hardKillGracePeriod * 1_000_000_000))

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
