import Testing
import SimControlDomain

@MainActor
@Suite("SimulatorRuntimeTests")
struct SimulatorRuntimeTests {
  @Test func preservesRuntimeMetadataAndCompatibility() {
    let runtime = SimulatorRuntime(
      id: "runtime-ios-18",
      name: "iOS 18.0",
      version: "18.0",
      buildVersion: "22A3351",
      platform: .iOS,
      isAvailable: true,
      supportedDeviceTypeIDs: ["device-type-iphone", "device-type-ipad"]
    )

    #expect(runtime.id == "runtime-ios-18")
    #expect(runtime.name == "iOS 18.0")
    #expect(runtime.version == "18.0")
    #expect(runtime.buildVersion == "22A3351")
    #expect(runtime.platform == .iOS)
    #expect(runtime.isAvailable)
    #expect(runtime.supportedDeviceTypeIDs == ["device-type-iphone", "device-type-ipad"])
  }

  @Test func platformCoversKnownAndUnknownFamilies() {
    #expect(SimulatorPlatform.iOS.rawValue == "iOS")
    #expect(SimulatorPlatform.watchOS.rawValue == "watchOS")
    #expect(SimulatorPlatform.tvOS.rawValue == "tvOS")
    #expect(SimulatorPlatform.visionOS.rawValue == "visionOS")
    #expect(SimulatorPlatform.unknown.rawValue == "unknown")
  }
}
