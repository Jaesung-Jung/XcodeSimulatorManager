import SimulatorRepositoryService
import Testing

@Suite("SimulatorRepositoryServiceSmokeTests")
struct SimulatorRepositoryServiceSmokeTests {
  @Test func repositoryCanBeConstructedAcrossModules() {
    _ = SimulatorRepository()
  }
}
