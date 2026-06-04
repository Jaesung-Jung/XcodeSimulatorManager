/// The result of a simulator inventory refresh.
public struct SimulatorRefreshResult: Equatable {
  /// The rebuilt snapshot when refresh completed successfully.
  public let snapshot: SimulatorSnapshot?

  /// The command result produced while checking the active Xcode path.
  public let xcodeCommandResult: CommandResult

  /// The command result produced while loading `simctl list -j`, when that step ran.
  public let listCommandResult: CommandResult?

  /// Repository-level refresh failure context, when refresh could not build a snapshot.
  public let diagnostic: String?

  /// Indicates whether refresh produced a new snapshot.
  public var succeeded: Bool { snapshot != nil && diagnostic == nil }

  /// Creates a simulator repository refresh result.
  public init(
    snapshot: SimulatorSnapshot?,
    xcodeCommandResult: CommandResult,
    listCommandResult: CommandResult?,
    diagnostic: String?
  ) {
    self.snapshot = snapshot
    self.xcodeCommandResult = xcodeCommandResult
    self.listCommandResult = listCommandResult
    self.diagnostic = diagnostic
  }
}
