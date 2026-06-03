import Foundation

/// A user-visible result for a simulator action initiated from SimControl.
///
/// `ActionResult` describes the higher-level app action rather than only the
/// shell command that may have been used to perform it. It can represent
/// successful actions, failed actions, and actions cancelled before command
/// execution, while optionally preserving the underlying ``CommandResult``.
struct ActionResult: Identifiable, Equatable, Hashable {
  /// The final outcome of a user-initiated action.
  enum Outcome: String, Equatable, Hashable {
    /// The action completed successfully.
    case success

    /// The action attempted work but failed.
    case failure

    /// The action was cancelled before completion.
    case cancelled
  }

  /// A stable identifier for this action result.
  let id: String

  /// A short user-facing action title, such as "Boot Device".
  let title: String

  /// The final outcome for the action.
  let outcome: Outcome

  /// Optional user-facing detail about the action outcome.
  let message: String?

  /// The command result associated with the action, when a command was run.
  let commandResult: CommandResult?

  /// The time at which the action result was produced.
  let occurredAt: Date
}
