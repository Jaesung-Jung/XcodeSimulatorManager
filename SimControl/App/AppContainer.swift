@MainActor
final class AppContainer {
  let commandExecutor: CommandExecutor
  let coreSimulatorService: CoreSimulatorService
  let simulatorRepository: SimulatorRepository
  let simulatorStore: SimulatorStore
  let settingsStore: SettingsStore
  let actionLogStore: ActionLogStore

  init() {
    let commandExecutor = CommandExecutor()
    let coreSimulatorService = CoreSimulatorService(commandExecutor: commandExecutor)
    let simulatorRepository = SimulatorRepository(coreSimulatorService: coreSimulatorService)

    self.commandExecutor = commandExecutor
    self.coreSimulatorService = coreSimulatorService
    self.simulatorRepository = simulatorRepository
    simulatorStore = SimulatorStore(repository: simulatorRepository)
    settingsStore = SettingsStore()
    actionLogStore = ActionLogStore()
  }
}
