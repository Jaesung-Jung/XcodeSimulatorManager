import Testing
import SimControlDomain

@MainActor
@Suite("DevicePairTests")
struct DevicePairTests {
  @Test func preservesPairDeviceIdentifiersAndState() {
    let pair = DevicePair(
      id: "pair-1",
      phoneDeviceID: "phone-device",
      watchDeviceID: "watch-device",
      state: .active
    )

    #expect(pair.id == "pair-1")
    #expect(pair.phoneDeviceID == "phone-device")
    #expect(pair.watchDeviceID == "watch-device")
    #expect(pair.state == .active)
  }

  @Test func supportsUnavailablePairState() {
    let pair = DevicePair(
      id: "pair-2",
      phoneDeviceID: "missing-phone",
      watchDeviceID: "watch-device",
      state: .unavailable
    )

    #expect(pair.state == .unavailable)
  }
}
