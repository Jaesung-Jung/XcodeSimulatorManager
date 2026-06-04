import AppSandboxResetService
import Testing

@Suite
struct AppSandboxResetServiceTests {
  @Test func serviceCanBeConstructedAcrossModules() {
    _ = AppSandboxResetService()
  }
}
