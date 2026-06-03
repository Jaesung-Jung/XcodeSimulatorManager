import Foundation

extension CommandExecutor {
  func closePipes(stdoutPipe: Pipe, stderrPipe: Pipe) {
    try? stdoutPipe.fileHandleForWriting.close()
    try? stderrPipe.fileHandleForWriting.close()
  }
}
