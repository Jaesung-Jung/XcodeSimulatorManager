import SimControlDomain

/// The command and optional refresh outputs produced by a developer tool workflow.
public struct DeveloperToolWorkflowResult: Equatable {
  public let commandResults: [CommandResult]
  public let refreshResult: SimulatorRefreshResult?
  public let preferredSelectedDeviceID: SimulatorDevice.ID?

  /// Creates a developer tool workflow result.
  public init(
    commandResults: [CommandResult],
    refreshResult: SimulatorRefreshResult?,
    preferredSelectedDeviceID: SimulatorDevice.ID?
  ) {
    self.commandResults = commandResults
    self.refreshResult = refreshResult
    self.preferredSelectedDeviceID = preferredSelectedDeviceID
  }
}
