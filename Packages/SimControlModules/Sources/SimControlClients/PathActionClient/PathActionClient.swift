import Foundation
import Dependencies
import SimControlDomain

/// A TCA dependency boundary for Finder and pasteboard path actions.
public struct PathActionClient: Sendable {
  /// Opens a filesystem URL in Finder.
  public var openInFinder: @Sendable (_ url: URL?, _ label: String) async -> CommandResult

  /// Copies a string value to the pasteboard.
  public var copy: @Sendable (_ value: String?, _ label: String) async -> CommandResult

  /// Copies a filesystem path to the pasteboard.
  public var copyPath: @Sendable (_ url: URL?, _ label: String) async -> CommandResult

  /// Creates a path action client from endpoint closures.
  public init(
    openInFinder: @escaping @Sendable (_ url: URL?, _ label: String) async -> CommandResult,
    copy: @escaping @Sendable (_ value: String?, _ label: String) async -> CommandResult,
    copyPath: @escaping @Sendable (_ url: URL?, _ label: String) async -> CommandResult
  ) {
    self.openInFinder = openInFinder
    self.copy = copy
    self.copyPath = copyPath
  }
}

extension PathActionClient: TestDependencyKey {
  /// An unimplemented client used by dependency tests unless overridden.
  public static let testValue = PathActionClient(
    openInFinder: unimplemented(
      "PathActionClient.openInFinder",
      placeholder: placeholderCommandResult("PathActionClient.openInFinder")
    ),
    copy: unimplemented(
      "PathActionClient.copy",
      placeholder: placeholderCommandResult("PathActionClient.copy")
    ),
    copyPath: unimplemented(
      "PathActionClient.copyPath",
      placeholder: placeholderCommandResult("PathActionClient.copyPath")
    )
  )
}

extension DependencyValues {
  /// The injected path action client.
  public var pathAction: PathActionClient {
    get { self[PathActionClient.self] }
    set { self[PathActionClient.self] = newValue }
  }
}
