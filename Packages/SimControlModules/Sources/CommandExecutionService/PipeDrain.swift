import Foundation

actor PipeDrain {
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
