import Foundation
import SimControlDomain

func placeholderCommandResult(_ endpoint: String) -> CommandResult {
  CommandResult(
    id: "unimplemented-\(endpoint)",
    executable: "unimplemented",
    arguments: [endpoint],
    stdout: "",
    stderr: "\(endpoint) is unimplemented.",
    exitCode: 1,
    duration: 0,
    startedAt: Date(timeIntervalSince1970: 0)
  )
}

func placeholderRefreshResult(_ endpoint: String) -> SimulatorRefreshResult {
  SimulatorRefreshResult(
    snapshot: nil,
    xcodeCommandResult: placeholderCommandResult(endpoint),
    listCommandResult: nil,
    diagnostic: "\(endpoint) is unimplemented."
  )
}
