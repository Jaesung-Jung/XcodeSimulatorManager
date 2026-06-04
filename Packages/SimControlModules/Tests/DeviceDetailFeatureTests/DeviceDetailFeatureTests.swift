import ComposableArchitecture
import DeviceDetailFeature
import SimControlDomain
import Testing

@Suite("DeviceDetailFeatureTests")
@MainActor
struct DeviceDetailFeatureTests {
  @Test func stateCanBeConstructedAcrossModules() {
    let device = SimulatorDevice(
      id: "device-1",
      udid: "device-1",
      name: "iPhone 16",
      runtimeID: "runtime-1",
      deviceTypeID: "type-1",
      platform: .iOS,
      state: .booted,
      isAvailable: true,
      dataPath: nil,
      logPath: nil,
      lastBootedAt: nil,
      dataPathSize: nil
    )

    let state = DeviceDetailFeature.State(device: device)

    #expect(state.device?.id == device.id)
    #expect(state.developerTools.device?.id == device.id)
  }

  @Test func reducerCanBeConstructedAcrossModules() async {
    let store = TestStore(initialState: DeviceDetailFeature.State()) {
      DeviceDetailFeature()
    }

    await store.send(.openSimulatorAppButtonTapped)
  }
}
