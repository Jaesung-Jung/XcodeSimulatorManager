import PathActionService
import Testing

@Suite("PathActionServiceSmokeTests")
struct PathActionServiceSmokeTests {
  @Test func serviceCanBeConstructedAcrossModules() {
    _ = PathActionService()
  }
}
