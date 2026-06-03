import SimControlClients
import SimControlInfrastructure

public extension SimulatorRepositoryClient {
  /// Creates a live simulator repository client backed by an existing repository instance.
  static func live(repository: SimulatorRepository) -> Self {
    Self {
      await repository.refresh()
    }
  }
}
