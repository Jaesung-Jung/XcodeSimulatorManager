import ComposableArchitecture
import SimControlClients
import SimControlClientsLive
import SimControlInfrastructure

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
      $0.simulatorRepository = .live(repository: simulatorRepository)
      $0.coreSimulatorService = .live(service: coreSimulatorService)
      $0.appSandboxReset = .live(service: appSandboxResetService)
      $0.pathAction = .live(service: pathActionService)
    }
  }
}
