import ComposableArchitecture

@MainActor
final class AppContainer {
  let commandExecutor: CommandExecutor
  let coreSimulatorService: CoreSimulatorService
  let simulatorRepository: SimulatorRepository
  let settingsStore: SettingsStore
  let actionLogStore: ActionLogStore
  let mainWindowStore: StoreOf<MainWindowFeature>

  init() {
    let commandExecutor = CommandExecutor()
    let coreSimulatorService = CoreSimulatorService(commandExecutor: commandExecutor)
    let simulatorRepository = SimulatorRepository(coreSimulatorService: coreSimulatorService)

    self.commandExecutor = commandExecutor
    self.coreSimulatorService = coreSimulatorService
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
    }
  }
}
