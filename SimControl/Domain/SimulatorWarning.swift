/// A recoverable warning discovered while building or using simulator state.
///
/// Warnings keep partial inventory useful by preserving context for unavailable
/// runtimes, missing paths, permission issues, parser fallbacks, and related
/// non-fatal problems.
struct SimulatorWarning: Identifiable, Equatable, Hashable {
  /// The importance of a simulator warning.
  enum Severity: String, Equatable, Hashable {
    /// Informational context that does not block work.
    case info

    /// A recoverable issue that may affect part of the UI.
    case warning

    /// A serious issue that prevents a specific operation or data source.
    case error
  }

  /// The subsystem or domain area that produced a warning.
  enum Category: String, Equatable, Hashable {
    /// Xcode selection or environment warning.
    case xcode

    /// `simctl` command warning.
    case simctl

    /// Data parsing warning.
    case parsing

    /// Runtime inventory warning.
    case runtime

    /// Simulator device warning.
    case device

    /// Installed app warning.
    case app

    /// Device pair warning.
    case pair

    /// Permission warning.
    case permissions

    /// Filesystem warning.
    case filesystem

    /// Link folder warning.
    case links
  }

  /// A stable identifier for the warning.
  let id: String

  /// The warning severity.
  let severity: Severity

  /// The category that best describes the warning source.
  let category: Category

  /// A user-facing warning message.
  let message: String

  /// An optional related domain identifier, such as a device or runtime id.
  let relatedID: String?
}
