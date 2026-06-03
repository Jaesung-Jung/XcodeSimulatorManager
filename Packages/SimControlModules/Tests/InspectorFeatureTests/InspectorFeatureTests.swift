import ComposableArchitecture
import InspectorFeature
import SimControlDomain
import Testing

@Suite
@MainActor
struct InspectorFeatureTests {
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

    let state = InspectorFeature.State(device: device)

    #expect(state.device?.id == device.id)
  }

  @Test func reducerCanBeConstructedAcrossModules() async {
    let store = TestStore(initialState: InspectorFeature.State()) {
      InspectorFeature()
    }

    await store.send(.copyDeviceUDIDButtonTapped("device-1"))
  }
}
