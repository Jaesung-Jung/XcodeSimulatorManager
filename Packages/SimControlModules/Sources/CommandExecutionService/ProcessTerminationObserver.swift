import Foundation

actor ProcessTerminationObserver {
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
