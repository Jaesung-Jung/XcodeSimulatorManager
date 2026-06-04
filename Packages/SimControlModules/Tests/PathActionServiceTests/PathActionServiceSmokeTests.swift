import PathActionService
import Testing

@Suite
struct PathActionServiceSmokeTests {
  @Test func serviceCanBeConstructedAcrossModules() {
    _ = PathActionService()
  }
}
