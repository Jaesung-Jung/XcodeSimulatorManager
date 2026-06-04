import SimControlInfrastructure
import Testing

@Suite("SimControlInfrastructureSmokeTests")
struct SimControlInfrastructureSmokeTests {
  @Test func umbrellaExportsConcreteServices() {
    _ = CommandExecutor()
    _ = CoreSimulatorService()
    _ = AppContainerScanner()
    _ = AppSandboxResetService()
    _ = PathActionService()
    _ = SimulatorRepository()
  }
}
