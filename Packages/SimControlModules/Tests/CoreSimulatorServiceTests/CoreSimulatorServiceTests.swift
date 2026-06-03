import CoreSimulatorService
import Testing

@Suite
struct CoreSimulatorServiceSmokeTests {
  @Test func serviceCanBeConstructedAcrossModules() {
    _ = CoreSimulatorService()
  }
}
