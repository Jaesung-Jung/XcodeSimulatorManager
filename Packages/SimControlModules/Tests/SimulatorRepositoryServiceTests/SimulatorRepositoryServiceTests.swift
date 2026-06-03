import SimulatorRepositoryService
import Testing

@Suite
struct SimulatorRepositoryServiceSmokeTests {
  @Test func repositoryCanBeConstructedAcrossModules() {
    _ = SimulatorRepository()
  }
}
