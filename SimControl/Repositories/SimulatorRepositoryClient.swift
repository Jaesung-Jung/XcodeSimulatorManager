import ComposableArchitecture
import SimControlInfrastructure

struct SimulatorRepositoryClient: Sendable {
  var refresh: @Sendable () async -> SimulatorRepository.RefreshResult
}

extension SimulatorRepositoryClient: DependencyKey {
  static var liveValue: SimulatorRepositoryClient {
    let repository = SimulatorRepository()

    return SimulatorRepositoryClient {
      await repository.refresh()
    }
  }
}

extension DependencyValues {
  var simulatorRepository: SimulatorRepositoryClient {
    get { self[SimulatorRepositoryClient.self] }
    set { self[SimulatorRepositoryClient.self] = newValue }
  }
}
