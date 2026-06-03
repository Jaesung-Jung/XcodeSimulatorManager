import Foundation
import SimControlDomain

extension CommandResult {
  public var commandLineSummary: String {
    let executableName = URL(fileURLWithPath: executable).lastPathComponent
    return ([executableName] + arguments).joined(separator: " ")
  }

  public var durationTitle: String {
    String(format: "%.2fs", duration)
  }
}
