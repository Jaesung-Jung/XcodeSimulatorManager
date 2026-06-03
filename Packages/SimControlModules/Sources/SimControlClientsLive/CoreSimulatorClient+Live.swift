import SimControlClients
import SimControlInfrastructure

public extension CoreSimulatorClient {
  /// Creates a live CoreSimulator client backed by an existing service instance.
  static func live(service: CoreSimulatorService) -> Self {
    Self(
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
      },
      getAppContainer: { deviceID, bundleID, container in
        await service.getAppContainer(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      },
      openURL: { deviceID, urlString in
        await service.openURL(deviceID: deviceID, urlString: urlString)
      },
      pushNotification: { deviceID, bundleID, payloadJSON in
        await service.pushNotification(
          deviceID: deviceID,
          bundleID: bundleID,
          payloadJSON: payloadJSON
        )
      },
      setPrivacyPermission: { deviceID, action, serviceName, bundleID in
        await service.setPrivacyPermission(
          deviceID: deviceID,
          action: action,
          service: serviceName,
          bundleID: bundleID
        )
      },
      setLocation: { deviceID, coordinate in
        await service.setLocation(deviceID: deviceID, coordinate: coordinate)
      },
      clearLocation: { deviceID in
        await service.clearLocation(deviceID: deviceID)
      },
      setStatusBarOverride: { deviceID, arguments in
        await service.setStatusBarOverride(deviceID: deviceID, arguments: arguments)
      },
      clearStatusBarOverride: { deviceID in
        await service.clearStatusBarOverride(deviceID: deviceID)
      }
    )
  }
}
