import ComposableArchitecture
import MainWindowFeature
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
    }
    settingsStore = Store(initialState: SettingsFeature.State()) {
      SettingsFeature()
    } withDependencies: {
      $0.userSettings = .live()
    }
  }
}
