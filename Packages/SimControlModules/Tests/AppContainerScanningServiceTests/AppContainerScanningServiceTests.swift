import AppContainerScanningService
import Testing

@Suite("AppContainerScanningServiceSmokeTests")
struct AppContainerScanningServiceSmokeTests {
  @Test func scannerCanBeConstructedAcrossModules() {
    _ = AppContainerScanner()
  }
}
