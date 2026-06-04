import AppSandboxResetService
import Testing

@Suite("AppSandboxResetServiceTests")
struct AppSandboxResetServiceTests {
  @Test func serviceCanBeConstructedAcrossModules() {
    _ = AppSandboxResetService()
  }
}
