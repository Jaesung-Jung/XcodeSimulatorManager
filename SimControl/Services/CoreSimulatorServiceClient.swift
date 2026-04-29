import ComposableArchitecture
import Foundation

struct CoreSimulatorServiceClient: Sendable {
  var openSimulatorApp: @Sendable () async -> CommandResult
  var bootDevice: @Sendable (_ id: String) async -> CommandResult
  var bootDeviceIfNeeded: @Sendable (_ id: String) async -> CommandResult
  var shutdownDevice: @Sendable (_ id: String) async -> CommandResult
  var createDevice: @Sendable (_ name: String, _ deviceTypeID: String, _ runtimeID: String) async -> CommandResult
  var cloneDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult
  var renameDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult
  var eraseDevice: @Sendable (_ id: String) async -> CommandResult
  var deleteDevice: @Sendable (_ id: String) async -> CommandResult
  var pairDevices: @Sendable (_ watchDeviceID: String, _ phoneDeviceID: String) async -> CommandResult
  var unpairDevice: @Sendable (_ pairID: String) async -> CommandResult
  var launchApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult
  var terminateApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult
  var uninstallApp: @Sendable (_ deviceID: String, _ bundleID: String) async -> CommandResult
  var installApp: @Sendable (_ deviceID: String, _ appBundlePath: URL) async -> CommandResult
}

extension CoreSimulatorServiceClient: DependencyKey {
  static var liveValue: CoreSimulatorServiceClient {
    let service = CoreSimulatorService()

    return CoreSimulatorServiceClient(
      openSimulatorApp: {
        await service.openSimulatorApp()
      },
      bootDevice: { id in
        await service.bootDevice(id: id)
      },
      bootDeviceIfNeeded: { id in
        await service.bootDeviceIfNeeded(id: id)
      },
      shutdownDevice: { id in
        await service.shutdownDevice(id: id)
      },
      createDevice: { name, deviceTypeID, runtimeID in
        await service.createDevice(
          name: name,
          deviceTypeID: deviceTypeID,
          runtimeID: runtimeID
        )
      },
      cloneDevice: { id, name in
        await service.cloneDevice(id: id, name: name)
      },
      renameDevice: { id, name in
        await service.renameDevice(id: id, name: name)
      },
      eraseDevice: { id in
        await service.eraseDevice(id: id)
      },
      deleteDevice: { id in
        await service.deleteDevice(id: id)
      },
      pairDevices: { watchDeviceID, phoneDeviceID in
        await service.pairDevices(
          watchDeviceID: watchDeviceID,
          phoneDeviceID: phoneDeviceID
        )
      },
      unpairDevice: { pairID in
        await service.unpairDevice(pairID: pairID)
      },
      launchApp: { deviceID, bundleID in
        await service.launchApp(deviceID: deviceID, bundleID: bundleID)
      },
      terminateApp: { deviceID, bundleID in
        await service.terminateApp(deviceID: deviceID, bundleID: bundleID)
      },
      uninstallApp: { deviceID, bundleID in
        await service.uninstallApp(deviceID: deviceID, bundleID: bundleID)
      },
      installApp: { deviceID, appBundlePath in
        await service.installApp(deviceID: deviceID, appBundlePath: appBundlePath)
      }
    )
  }
}

extension DependencyValues {
  var coreSimulatorService: CoreSimulatorServiceClient {
    get { self[CoreSimulatorServiceClient.self] }
    set { self[CoreSimulatorServiceClient.self] = newValue }
  }
}
