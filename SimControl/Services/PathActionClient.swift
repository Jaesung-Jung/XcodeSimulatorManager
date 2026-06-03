import ComposableArchitecture
import SimControlDomain
import Foundation

struct PathActionClient: Sendable {
  var openInFinder: @Sendable (_ url: URL?, _ label: String) async -> CommandResult
  var copy: @Sendable (_ value: String?, _ label: String) async -> CommandResult
  var copyPath: @Sendable (_ url: URL?, _ label: String) async -> CommandResult
}

extension PathActionClient: DependencyKey {
  static var liveValue: PathActionClient {
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
  var pathAction: PathActionClient {
    get { self[PathActionClient.self] }
    set { self[PathActionClient.self] = newValue }
  }
}
