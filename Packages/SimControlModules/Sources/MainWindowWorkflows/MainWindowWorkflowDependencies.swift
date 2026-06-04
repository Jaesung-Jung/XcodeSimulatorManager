import Dependencies
import SimControlClients

extension InventoryWorkflowClient: TestDependencyKey {
  public static var testValue: Self {
    @Dependency(\.simulatorRepository) var simulatorRepository
    @Dependency(\.coreSimulatorService) var coreSimulatorService

    return .live(
      simulatorRepository: simulatorRepository,
      coreSimulatorService: coreSimulatorService
    )
  }
}

extension DeviceLifecycleWorkflowClient: TestDependencyKey {
  public static var testValue: Self {
    @Dependency(\.coreSimulatorService) var coreSimulatorService
    @Dependency(\.simulatorRepository) var simulatorRepository

    return .live(
      coreSimulatorService: coreSimulatorService,
      simulatorRepository: simulatorRepository
    )
  }
}

extension InstalledAppWorkflowClient: TestDependencyKey {
  public static var testValue: Self {
    @Dependency(\.coreSimulatorService) var coreSimulatorService
    @Dependency(\.appSandboxReset) var appSandboxReset
    @Dependency(\.simulatorRepository) var simulatorRepository

    return .live(
      coreSimulatorService: coreSimulatorService,
      appSandboxReset: appSandboxReset,
      simulatorRepository: simulatorRepository
    )
  }
}

extension DeveloperToolWorkflowClient: TestDependencyKey {
  public static var testValue: Self {
    @Dependency(\.coreSimulatorService) var coreSimulatorService
    @Dependency(\.simulatorRepository) var simulatorRepository

    return .live(
      coreSimulatorService: coreSimulatorService,
      simulatorRepository: simulatorRepository
    )
  }
}

extension PathActionWorkflowClient: TestDependencyKey {
  public static var testValue: Self {
    @Dependency(\.coreSimulatorService) var coreSimulatorService
    @Dependency(\.pathAction) var pathAction

    return .live(
      coreSimulatorService: coreSimulatorService,
      pathAction: pathAction
    )
  }
}

extension DependencyValues {
  /// The injected main window inventory workflow.
  public var inventoryWorkflow: InventoryWorkflowClient {
    get { self[InventoryWorkflowClient.self] }
    set { self[InventoryWorkflowClient.self] = newValue }
  }

  /// The injected main window device lifecycle workflow.
  public var deviceLifecycleWorkflow: DeviceLifecycleWorkflowClient {
    get { self[DeviceLifecycleWorkflowClient.self] }
    set { self[DeviceLifecycleWorkflowClient.self] = newValue }
  }

  /// The injected main window installed app workflow.
  public var installedAppWorkflow: InstalledAppWorkflowClient {
    get { self[InstalledAppWorkflowClient.self] }
    set { self[InstalledAppWorkflowClient.self] = newValue }
  }

  /// The injected main window developer tool workflow.
  public var developerToolWorkflow: DeveloperToolWorkflowClient {
    get { self[DeveloperToolWorkflowClient.self] }
    set { self[DeveloperToolWorkflowClient.self] = newValue }
  }

  /// The injected main window path action workflow.
  public var pathActionWorkflow: PathActionWorkflowClient {
    get { self[PathActionWorkflowClient.self] }
    set { self[PathActionWorkflowClient.self] = newValue }
  }
}
