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
    }
  }
}
