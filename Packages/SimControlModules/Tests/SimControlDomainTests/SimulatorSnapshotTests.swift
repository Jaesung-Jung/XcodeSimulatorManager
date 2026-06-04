import Foundation
import Testing
import SimControlDomain

@MainActor
@Suite
struct SimulatorSnapshotTests {
  @Test func preservesEnvironmentInventoryAndWarnings() {
    let generatedAt = Date(timeIntervalSince1970: 200)
    let xcode = XcodeSelection(
      developerPath: URL(fileURLWithPath: "/Applications/Xcode.app/Contents/Developer"),
      version: "17.0",
      isValid: true
    )
    let runtime = SimulatorRuntime(
      id: "runtime-ios-18",
      name: "iOS 18.0",
      version: "18.0",
      buildVersion: "22A3351",
      platform: .iOS,
      isAvailable: true,
      supportedDeviceTypeIDs: ["device-type-iphone"]
    )
    let deviceType = SimulatorDeviceType(
      id: "device-type-iphone",
      name: "iPhone 16",
      productFamily: "iPhone",
      modelIdentifier: "iPhone17,3"
    )
    let device = SimulatorDevice(
      id: "device-1",
      udid: "UDID-1",
      name: "iPhone 16",
      runtimeID: runtime.id,
      deviceTypeID: deviceType.id,
      platform: .iOS,
      state: .booted,
      isAvailable: true,
      dataPath: URL(fileURLWithPath: "/tmp/Devices/device-1/data"),
      logPath: URL(fileURLWithPath: "/tmp/Devices/device-1/logs"),
      lastBootedAt: Date(timeIntervalSince1970: 300),
      dataPathSize: 1_024
    )
    let pair = DevicePair(
      id: "pair-1",
      phoneDeviceID: device.id,
      watchDeviceID: "watch-device",
      state: .active
    )
    let app = InstalledApp(
      id: "\(device.id):com.example.app",
      bundleID: "com.example.app",
      displayName: "Example",
      version: "1.0",
      build: "100",
      deviceID: device.id,
      bundleContainer: nil,
      dataContainer: nil,
      appBundlePath: nil,
      appGroups: [],
      iconPath: nil
    )
    let warning = SimulatorWarning(
      id: "warning-1",
      severity: .warning,
      category: .runtime,
      message: "Runtime unavailable",
      relatedID: runtime.id
    )
    let snapshot = SimulatorSnapshot(
      generatedAt: generatedAt,
      xcode: xcode,
      runtimes: [runtime],
      deviceTypes: [deviceType],
      devices: [device],
      pairs: [pair],
      installedAppsByDeviceID: [device.id: [app]],
      warnings: [warning]
    )

    #expect(snapshot.generatedAt == generatedAt)
    #expect(snapshot.xcode == xcode)
    #expect(snapshot.runtimes == [runtime])
    #expect(snapshot.deviceTypes == [deviceType])
    #expect(snapshot.devices == [device])
    #expect(snapshot.pairs == [pair])
    #expect(snapshot.installedAppsByDeviceID[device.id] == [app])
    #expect(snapshot.warnings == [warning])
  }
}
