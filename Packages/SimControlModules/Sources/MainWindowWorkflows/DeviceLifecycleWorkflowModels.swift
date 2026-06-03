import SimControlDomain

/// The command and refresh outputs produced by a device lifecycle workflow.
public struct DeviceLifecycleWorkflowResult: Equatable {
  public let commandResult: CommandResult
  public let refreshResult: SimulatorRefreshResult
  public let preferredSelectedDeviceID: SimulatorDevice.ID?

  /// Creates a device lifecycle workflow result.
  public init(
    commandResult: CommandResult,
    refreshResult: SimulatorRefreshResult,
    preferredSelectedDeviceID: SimulatorDevice.ID?
  ) {
    self.commandResult = commandResult
    self.refreshResult = refreshResult
    self.preferredSelectedDeviceID = preferredSelectedDeviceID
  }
}
