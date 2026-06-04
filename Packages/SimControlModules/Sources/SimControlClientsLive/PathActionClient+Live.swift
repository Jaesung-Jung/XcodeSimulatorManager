import SimControlClients
import SimControlInfrastructure

public extension PathActionClient {
  /// Creates a live path action client backed by an existing service instance.
  static func live(service: PathActionService) -> Self {
    Self(
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
