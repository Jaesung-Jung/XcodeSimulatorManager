import Dependencies
import SimControlDomain

/// A TCA dependency boundary for simulator inventory refreshes.
public struct SimulatorRepositoryClient: Sendable {
  /// Refreshes simulator inventory from the backing repository.
  public var refresh: @Sendable () async -> SimulatorRefreshResult

  /// Creates a simulator repository client from an inventory refresh endpoint.
  public init(refresh: @escaping @Sendable () async -> SimulatorRefreshResult) {
    self.refresh = refresh
  }
}

extension SimulatorRepositoryClient: TestDependencyKey {
  /// An unimplemented client used by dependency tests unless overridden.
  public static let testValue = SimulatorRepositoryClient(
    refresh: unimplemented(
      "SimulatorRepositoryClient.refresh",
      placeholder: placeholderRefreshResult("SimulatorRepositoryClient.refresh")
    )
  )
}

extension DependencyValues {
  /// The injected simulator repository client.
  public var simulatorRepository: SimulatorRepositoryClient {
    get { self[SimulatorRepositoryClient.self] }
    set { self[SimulatorRepositoryClient.self] = newValue }
  }
}
