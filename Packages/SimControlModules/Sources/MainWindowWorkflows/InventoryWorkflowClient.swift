import SimControlClients
import SimControlDomain

/// Runs main window inventory-oriented commands outside the reducer.
public struct InventoryWorkflowClient: Sendable {
  public var refresh: @Sendable () async -> SimulatorRefreshResult
  public var openSimulatorApp: @Sendable () async -> CommandResult

  /// Creates an inventory workflow from endpoint closures.
  public init(
    refresh: @escaping @Sendable () async -> SimulatorRefreshResult,
    openSimulatorApp: @escaping @Sendable () async -> CommandResult
  ) {
    self.refresh = refresh
    self.openSimulatorApp = openSimulatorApp
  }
}

public extension InventoryWorkflowClient {
  /// Creates an inventory workflow backed by dependency clients.
  static func live(
    simulatorRepository: SimulatorRepositoryClient,
    coreSimulatorService: CoreSimulatorClient
  ) -> Self {
    Self(
      refresh: {
        await simulatorRepository.refresh()
      },
      openSimulatorApp: {
        await coreSimulatorService.openSimulatorApp()
      }
    )
  }
}
