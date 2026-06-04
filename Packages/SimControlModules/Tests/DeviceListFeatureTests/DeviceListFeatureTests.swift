import ComposableArchitecture
import DeviceListFeature
import SimControlDomain
import Testing

@Suite("DeviceListFeatureTests")
@MainActor
struct DeviceListFeatureTests {
  @Test func stateCanBeConstructedAcrossModules() {
    let state = DeviceListFeature.State(
      devices: [
        SimulatorDevice(
          id: "device-1",
          udid: "device-1",
          name: "iPhone 16",
          runtimeID: "runtime-1",
          deviceTypeID: "type-1",
          platform: .iOS,
          state: .shutdown,
          isAvailable: true,
          dataPath: nil,
          logPath: nil,
          lastBootedAt: nil,
          dataPathSize: nil
        )
      ],
      selectedDeviceID: "device-1",
      totalDeviceCount: 1
    )

    #expect(state.devices.map(\.id) == ["device-1"])
    #expect(state.selectedDeviceID == "device-1")
    #expect(state.totalDeviceCount == 1)
  }

  @Test func selectionChangedStoresSelectedDeviceID() async {
    let store = TestStore(initialState: DeviceListFeature.State()) {
      DeviceListFeature()
    }

    await store.send(.selectionChanged("device-1")) {
      $0.selectedDeviceID = "device-1"
    }
  }
}
