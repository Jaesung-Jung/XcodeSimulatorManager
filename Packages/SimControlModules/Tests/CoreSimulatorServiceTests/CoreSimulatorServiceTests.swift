import CoreSimulatorService
import Testing

@Suite("CoreSimulatorServiceSmokeTests")
struct CoreSimulatorServiceSmokeTests {
  @Test func serviceCanBeConstructedAcrossModules() {
    _ = CoreSimulatorService()
  }
}
