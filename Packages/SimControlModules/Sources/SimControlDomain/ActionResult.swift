import Foundation

/// A user-visible result for a simulator action initiated from SimControl.
///
/// `ActionResult` describes the higher-level app action rather than only the
/// shell command that may have been used to perform it. It can represent
/// successful actions, failed actions, and actions cancelled before command
/// execution, while optionally preserving the underlying ``CommandResult``.
public struct ActionResult: Identifiable, Equatable, Hashable {
  /// The final outcome of a user-initiated action.
  public enum Outcome: String, Equatable, Hashable {
    /// The action completed successfully.
    case success

    /// The action attempted work but failed.
    case failure

    /// The action was cancelled before completion.
    case cancelled
  }

  /// A stable identifier for this action result.
  public let id: String

  /// A short user-facing action title, such as "Boot Device".
  public let title: String

  /// The final outcome for the action.
  public let outcome: Outcome

  /// Optional user-facing detail about the action outcome.
  public let message: String?

  /// The command result associated with the action, when a command was run.
  public let commandResult: CommandResult?

  /// The time at which the action result was produced.
  public let occurredAt: Date

  /// Creates a user-visible action result.
  public init(
    id: String,
    title: String,
    outcome: Outcome,
    message: String?,
    commandResult: CommandResult?,
    occurredAt: Date
  ) {
    self.id = id
    self.title = title
    self.outcome = outcome
    self.message = message
    self.commandResult = commandResult
    self.occurredAt = occurredAt
  }
}
