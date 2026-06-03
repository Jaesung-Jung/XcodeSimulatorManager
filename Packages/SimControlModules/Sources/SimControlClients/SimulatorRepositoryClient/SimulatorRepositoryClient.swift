import ComposableArchitecture
import SimControlInfrastructure

/// A TCA dependency boundary for simulator inventory refreshes.
public struct SimulatorRepositoryClient: Sendable {
  public var refresh: @Sendable () async -> SimulatorRepository.RefreshResult

  /// Creates a simulator repository client from an inventory refresh endpoint.
  public init(refresh: @escaping @Sendable () async -> SimulatorRepository.RefreshResult) {
    self.refresh = refresh
  }
}

extension SimulatorRepositoryClient: DependencyKey {
  public static var liveValue: SimulatorRepositoryClient {
    let repository = SimulatorRepository()

    return SimulatorRepositoryClient {
      await repository.refresh()
    }
  }
}

extension DependencyValues {
  /// The injected simulator repository client.
  public var simulatorRepository: SimulatorRepositoryClient {
    get { self[SimulatorRepositoryClient.self] }
    set { self[SimulatorRepositoryClient.self] = newValue }
  }
}
