import ComposableArchitecture
import DeveloperToolsFeature
import MainWindowFeatureSupport
import SimControlDomain
import Testing

@Suite("DeveloperToolsFeatureTests")
@MainActor
struct DeveloperToolsFeatureTests {
  @Test func stateCanValidateDeepLinksAcrossModules() {
    let validState = DeveloperToolsFeature.State(
      device: simulatorDevice(state: .booted),
      deepLinkURLString: "myapp://home"
    )
    let invalidState = DeveloperToolsFeature.State(
      device: simulatorDevice(state: .booted),
      deepLinkURLString: "example.com"
    )

    #expect(validState.openDeepLinkDisabledReason == nil)
    #expect(invalidState.openDeepLinkDisabledReason == "URL must include a scheme.")
  }

  @Test func reducerStoresDeepLinkURL() async {
    let store = TestStore(initialState: DeveloperToolsFeature.State()) {
      DeveloperToolsFeature()
    }

    await store.send(.deepLinkURLChanged("myapp://home")) {
      $0.deepLinkURLString = "myapp://home"
    }
  }

  private func simulatorDevice(state: SimulatorDevice.State) -> SimulatorDevice {
    SimulatorDevice(
      id: "device-1",
      udid: "device-1",
      name: "iPhone 16",
      runtimeID: "runtime-1",
      deviceTypeID: "type-1",
      platform: .iOS,
      state: state,
      isAvailable: true,
      dataPath: nil,
      logPath: nil,
      lastBootedAt: nil,
      dataPathSize: nil
    )
  }
}
