import SettingsFeature
import SwiftUI
import Testing

@Suite
struct SettingsFeatureSmokeTests {
  @Test func rootViewCanBeConstructedFromOutsideTheModule() {
    _ = SettingsRootView()
  }
}
