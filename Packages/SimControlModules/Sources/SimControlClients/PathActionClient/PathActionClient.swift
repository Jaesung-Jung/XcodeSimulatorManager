import Foundation
import ComposableArchitecture
import SimControlDomain
import SimControlInfrastructure

/// A TCA dependency boundary for Finder and pasteboard path actions.
public struct PathActionClient: Sendable {
  public var openInFinder: @Sendable (_ url: URL?, _ label: String) async -> CommandResult
  public var copy: @Sendable (_ value: String?, _ label: String) async -> CommandResult
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

extension PathActionClient: DependencyKey {
  public static var liveValue: PathActionClient {
    let service = PathActionService()

    return PathActionClient(
      openInFinder: { url, label in
        await service.openInFinder(url, label: label)
      },
      copy: { value, label in
        await service.copy(value, label: label)
      },
      copyPath: { url, label in
        await service.copyPath(url, label: label)
      }
    )
  }
}

extension DependencyValues {
  /// The injected path action client.
  public var pathAction: PathActionClient {
    get { self[PathActionClient.self] }
    set { self[PathActionClient.self] = newValue }
  }
}
