import MainWindowFeatureSupport
import Testing

@Suite("MainWindowFeatureSupportTests")
struct MainWindowFeatureSupportTests {
  @Test func commandStatesExposeTheirStoredValuesAcrossModules() {
    let deviceState = DeviceCommandState(command: .boot, deviceID: "device-1")
    let appState = AppCommandState(
      command: .installOnSimulator,
      sourceDeviceID: "source-device",
      appID: "app-1",
      targetDeviceID: "target-device"
    )

    #expect(deviceState.command == .boot)
    #expect(deviceState.deviceID == "device-1")
    #expect(appState.command == .installOnSimulator)
    #expect(appState.sourceDeviceID == "source-device")
    #expect(appState.appID == "app-1")
    #expect(appState.targetDeviceID == "target-device")
  }

  @Test func refreshAndAvailabilityStatesRemainEquatable() {
    #expect(InventoryRefreshState.idle == .idle)
    #expect(InventoryRefreshState.refreshing == .refreshing)
    #expect(InventoryRefreshState.failed(diagnostic: "simctl failed") == .failed(diagnostic: "simctl failed"))
    #expect(InstalledAppsAvailability.notLoaded == .notLoaded)
    #expect(InstalledAppsAvailability.loaded == .loaded)
  }
}
