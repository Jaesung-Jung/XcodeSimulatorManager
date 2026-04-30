import Testing
@testable import SimControl

@MainActor
@Suite
struct SimulatorDeviceTypeTests {
  @Test func preservesDeviceTypeMetadata() {
    let deviceType = SimulatorDeviceType(
      id: "device-type-iphone",
      name: "iPhone 16",
      productFamily: "iPhone",
      modelIdentifier: "iPhone17,3"
    )

    #expect(deviceType.id == "device-type-iphone")
    #expect(deviceType.name == "iPhone 16")
    #expect(deviceType.productFamily == "iPhone")
    #expect(deviceType.modelIdentifier == "iPhone17,3")
  }

  @Test func supportsUnknownOptionalMetadata() {
    let deviceType = SimulatorDeviceType(
      id: "device-type-unknown",
      name: "Unknown Device",
      productFamily: nil,
      modelIdentifier: nil
    )

    #expect(deviceType.productFamily == nil)
    #expect(deviceType.modelIdentifier == nil)
  }
}
