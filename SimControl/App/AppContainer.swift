import ComposableArchitecture

@MainActor
final class AppContainer {
  let commandExecutor: CommandExecutor
  let coreSimulatorService: CoreSimulatorService
  let appContainerScanner: AppContainerScanner
  let appSandboxResetService: AppSandboxResetService
  let pathActionService: PathActionService
  let simulatorRepository: SimulatorRepository
  let settingsStore: SettingsStore
  let actionLogStore: ActionLogStore
  let mainWindowStore: StoreOf<MainWindowFeature>

  init() {
    let commandExecutor = CommandExecutor()
    let coreSimulatorService = CoreSimulatorService(commandExecutor: commandExecutor)
    let appContainerScanner = AppContainerScanner()
    let appSandboxResetService = AppSandboxResetService()
    let pathActionService = PathActionService()
    let simulatorRepository = SimulatorRepository(
      coreSimulatorService: coreSimulatorService,
      appContainerScanner: appContainerScanner
    )

    self.commandExecutor = commandExecutor
    self.coreSimulatorService = coreSimulatorService
    self.appContainerScanner = appContainerScanner
    self.appSandboxResetService = appSandboxResetService
    self.pathActionService = pathActionService
    self.simulatorRepository = simulatorRepository
    settingsStore = SettingsStore()
    actionLogStore = ActionLogStore()
    mainWindowStore = Store(initialState: MainWindowFeature.State()) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        await simulatorRepository.refresh()
      }
      $0.coreSimulatorService.openSimulatorApp = {
        await coreSimulatorService.openSimulatorApp()
      }
      $0.coreSimulatorService.bootDevice = { id in
        await coreSimulatorService.bootDevice(id: id)
      }
      $0.coreSimulatorService.bootDeviceIfNeeded = { id in
        await coreSimulatorService.bootDeviceIfNeeded(id: id)
      }
      $0.coreSimulatorService.shutdownDevice = { id in
        await coreSimulatorService.shutdownDevice(id: id)
      }
      $0.coreSimulatorService.createDevice = { name, deviceTypeID, runtimeID in
        await coreSimulatorService.createDevice(
          name: name,
          deviceTypeID: deviceTypeID,
          runtimeID: runtimeID
        )
      }
      $0.coreSimulatorService.cloneDevice = { id, name in
        await coreSimulatorService.cloneDevice(id: id, name: name)
      }
      $0.coreSimulatorService.renameDevice = { id, name in
        await coreSimulatorService.renameDevice(id: id, name: name)
      }
      $0.coreSimulatorService.eraseDevice = { id in
        await coreSimulatorService.eraseDevice(id: id)
      }
      $0.coreSimulatorService.deleteDevice = { id in
        await coreSimulatorService.deleteDevice(id: id)
      }
      $0.coreSimulatorService.pairDevices = { watchDeviceID, phoneDeviceID in
        await coreSimulatorService.pairDevices(
          watchDeviceID: watchDeviceID,
          phoneDeviceID: phoneDeviceID
        )
      }
      $0.coreSimulatorService.unpairDevice = { pairID in
        await coreSimulatorService.unpairDevice(pairID: pairID)
      }
      $0.coreSimulatorService.launchApp = { deviceID, bundleID in
        await coreSimulatorService.launchApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.coreSimulatorService.terminateApp = { deviceID, bundleID in
        await coreSimulatorService.terminateApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.coreSimulatorService.uninstallApp = { deviceID, bundleID in
        await coreSimulatorService.uninstallApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.coreSimulatorService.installApp = { deviceID, appBundlePath in
        await coreSimulatorService.installApp(deviceID: deviceID, appBundlePath: appBundlePath)
      }
      $0.coreSimulatorService.getAppContainer = { deviceID, bundleID, container in
        await coreSimulatorService.getAppContainer(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      }
      $0.coreSimulatorService.openURL = { deviceID, urlString in
        await coreSimulatorService.openURL(deviceID: deviceID, urlString: urlString)
      }
      $0.coreSimulatorService.pushNotification = { deviceID, bundleID, payloadJSON in
        await coreSimulatorService.pushNotification(
          deviceID: deviceID,
          bundleID: bundleID,
          payloadJSON: payloadJSON
        )
      }
      $0.coreSimulatorService.setPrivacyPermission = { deviceID, action, serviceName, bundleID in
        await coreSimulatorService.setPrivacyPermission(
          deviceID: deviceID,
          action: action,
          service: serviceName,
          bundleID: bundleID
        )
      }
      $0.coreSimulatorService.setLocation = { deviceID, coordinate in
        await coreSimulatorService.setLocation(deviceID: deviceID, coordinate: coordinate)
      }
      $0.coreSimulatorService.clearLocation = { deviceID in
        await coreSimulatorService.clearLocation(deviceID: deviceID)
      }
      $0.appSandboxReset.resetSandbox = { dataContainer in
        await appSandboxResetService.resetSandbox(at: dataContainer)
      }
      $0.pathAction.openInFinder = { url, label in
        await pathActionService.openInFinder(url, label: label)
      }
      $0.pathAction.copy = { value, label in
        await pathActionService.copy(value, label: label)
      }
      $0.pathAction.copyPath = { url, label in
        await pathActionService.copyPath(url, label: label)
      }
    }
  }
}
