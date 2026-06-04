import ComposableArchitecture
import MainWindowFeature
import MainWindowWorkflows
import SettingsFeature
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
  let mainWindowStore: StoreOf<MainWindowFeature>
  let settingsStore: StoreOf<SettingsFeature>

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
    mainWindowStore = Store(initialState: MainWindowFeature.State.initial) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository = .live(repository: simulatorRepository)
      $0.coreSimulatorService = .live(service: coreSimulatorService)
      $0.appSandboxReset = .live(service: appSandboxResetService)
      $0.pathAction = .live(service: pathActionService)
      $0.inventoryWorkflow = .live(
        simulatorRepository: $0.simulatorRepository,
        coreSimulatorService: $0.coreSimulatorService
      )
      $0.deviceLifecycleWorkflow = .live(
        coreSimulatorService: $0.coreSimulatorService,
        simulatorRepository: $0.simulatorRepository
      )
      $0.installedAppWorkflow = .live(
        coreSimulatorService: $0.coreSimulatorService,
        appSandboxReset: $0.appSandboxReset,
        simulatorRepository: $0.simulatorRepository
      )
      $0.developerToolWorkflow = .live(
        coreSimulatorService: $0.coreSimulatorService,
        simulatorRepository: $0.simulatorRepository
      )
      $0.pathActionWorkflow = .live(
        coreSimulatorService: $0.coreSimulatorService,
        pathAction: $0.pathAction
      )
    }
    settingsStore = Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings = .live()
    }
  }
}
