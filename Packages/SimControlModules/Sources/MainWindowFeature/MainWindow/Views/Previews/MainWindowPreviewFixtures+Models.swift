import Foundation
import SimControlDomain

#if DEBUG

extension MainWindowPreviewFixtures {
  static let runtime = SimulatorRuntime(
    id: "com.apple.CoreSimulator.SimRuntime.iOS-26-4",
    name: "iOS 26.4",
    version: "26.4",
    buildVersion: "23E244",
    platform: .iOS,
    isAvailable: true,
    supportedDeviceTypeIDs: ["com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro"]
  )

  static let deviceType = SimulatorDeviceType(
    id: "com.apple.CoreSimulator.SimDeviceType.iPhone-17-Pro",
    name: "iPhone 17 Pro",
    productFamily: "iPhone",
    modelIdentifier: "iPhone18,1"
  )

  static let device = SimulatorDevice(
    id: "PREVIEW-DEVICE-1",
    udid: "PREVIEW-DEVICE-1",
    name: "iPhone 17 Pro",
    runtimeID: runtime.id,
    deviceTypeID: deviceType.id,
    platform: .iOS,
    state: .booted,
    isAvailable: true,
    dataPath: URL(fileURLWithPath: "/Users/example/Library/Developer/CoreSimulator/Devices/PREVIEW-DEVICE-1/data"),
    logPath: URL(fileURLWithPath: "/Users/example/Library/Logs/CoreSimulator/PREVIEW-DEVICE-1"),
    lastBootedAt: Date(timeIntervalSince1970: 1_000),
    dataPathSize: 5_200_000_000
  )

  static let app = InstalledApp(
    id: "PREVIEW-DEVICE-1:com.example.preview",
    bundleID: "com.example.preview",
    displayName: "Preview App",
    version: "1.0",
    build: "100",
    deviceID: device.id,
    bundleContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle"),
    dataContainer: URL(fileURLWithPath: "/tmp/PreviewApp/Data"),
    appBundlePath: URL(fileURLWithPath: "/tmp/PreviewApp/Bundle/Preview.app"),
    appGroups: [
      AppGroupContainer(
        id: "group.com.example.preview",
        groupID: "group.com.example.preview",
        path: URL(fileURLWithPath: "/tmp/PreviewApp/Groups/group.com.example.preview")
      )
    ],
    iconPath: nil
  )
}

#endif
