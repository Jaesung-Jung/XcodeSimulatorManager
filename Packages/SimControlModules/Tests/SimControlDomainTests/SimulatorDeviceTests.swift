import Foundation
import Testing
import SimControlDomain

@MainActor
@Suite("SimulatorDeviceTests")
struct SimulatorDeviceTests {
  @Test func preservesInventoryFieldsAndPaths() {
    let lastBootedAt = Date(timeIntervalSince1970: 300)
    let device = SimulatorDevice(
      id: "device-1",
      udid: "UDID-1",
      name: "iPhone 16",
      runtimeID: "runtime-ios-18",
      deviceTypeID: "device-type-iphone",
      platform: .iOS,
      state: .booted,
      isAvailable: true,
      dataPath: URL(fileURLWithPath: "/tmp/Devices/device-1/data"),
      logPath: URL(fileURLWithPath: "/tmp/Devices/device-1/logs"),
      lastBootedAt: lastBootedAt,
      dataPathSize: 1_024
    )

    #expect(device.id == "device-1")
    #expect(device.udid == "UDID-1")
    #expect(device.name == "iPhone 16")
    #expect(device.runtimeID == "runtime-ios-18")
    #expect(device.deviceTypeID == "device-type-iphone")
    #expect(device.platform == .iOS)
    #expect(device.state == .booted)
    #expect(device.isAvailable)
    #expect(device.dataPath == URL(fileURLWithPath: "/tmp/Devices/device-1/data"))
    #expect(device.logPath == URL(fileURLWithPath: "/tmp/Devices/device-1/logs"))
    #expect(device.lastBootedAt == lastBootedAt)
    #expect(device.dataPathSize == 1_024)
  }

  @Test func supportsUnavailableDevicesWithMissingOptionalPaths() {
    let device = SimulatorDevice(
      id: "device-2",
      udid: "UDID-2",
      name: "Unavailable Device",
      runtimeID: "runtime-ios-18",
      deviceTypeID: "device-type-iphone",
      platform: .iOS,
      state: .unknown,
      isAvailable: false,
      dataPath: nil,
      logPath: nil,
      lastBootedAt: nil,
      dataPathSize: nil
    )

    #expect(!device.isAvailable)
    #expect(device.state == .unknown)
    #expect(device.dataPath == nil)
    #expect(device.logPath == nil)
    #expect(device.lastBootedAt == nil)
    #expect(device.dataPathSize == nil)
  }
}
