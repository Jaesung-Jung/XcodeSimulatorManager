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
    }
  }
}
