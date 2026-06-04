import AppContainerScanningService
import Testing

@Suite
struct AppContainerScanningServiceSmokeTests {
  @Test func scannerCanBeConstructedAcrossModules() {
    _ = AppContainerScanner()
  }
}
