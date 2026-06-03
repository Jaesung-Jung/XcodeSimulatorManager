import Foundation
import MainWindowSheetsFeature
import SimControlDomain
import Testing

@Suite
struct MainWindowSheetsFeatureSmokeTests {
  @Test func modelsAndViewsCanBeConstructedAcrossModules() {
    let runtime = SimulatorRuntime(
      id: "runtime",
      name: "iOS",
      version: "26.4",
      buildVersion: "23E244",
      platform: .iOS,
      isAvailable: true,
      supportedDeviceTypeIDs: ["device-type"]
    )
    let deviceType = SimulatorDeviceType(
      id: "device-type",
      name: "iPhone",
      productFamily: "iPhone",
      modelIdentifier: "iPhone18,1"
    )
    let device = SimulatorDevice(
      id: "device",
      udid: "device",
      name: "iPhone",
      runtimeID: runtime.id,
      deviceTypeID: deviceType.id,
      platform: .iOS,
      state: .booted,
      isAvailable: true,
      dataPath: nil,
      logPath: nil,
      lastBootedAt: nil,
      dataPathSize: nil
    )
    let appBundlePath = URL(fileURLWithPath: "/tmp/Preview.app")

    _ = CreateDeviceView(
      formState: CreateDeviceFormState(),
      runtimes: [runtime],
      deviceTypes: [deviceType]
    ) { _ in }

    _ = InstallAppOnSimulatorView(
      formState: InstallAppTargetFormState(
        sourceAppID: "app",
        sourceDeviceID: device.id,
        appName: "Preview App",
        bundleID: "com.example.preview",
        appBundlePath: appBundlePath,
        targetDeviceID: device.id,
        launchAfterInstall: true
      ),
      targetCandidates: [InstallAppTargetCandidate(device: device)]
    ) { _ in }

    _ = DeviceLifecycleSheet.erase(
      DeviceDestructiveConfirmationState(
        deviceID: device.id,
        deviceName: device.name,
        deviceUDID: device.udid
      )
    )
  }
}
