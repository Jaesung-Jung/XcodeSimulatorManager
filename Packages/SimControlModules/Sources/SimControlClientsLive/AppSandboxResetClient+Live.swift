import SimControlClients
import SimControlInfrastructure

public extension AppSandboxResetClient {
  /// Creates a live app sandbox reset client backed by an existing service instance.
  static func live(service: AppSandboxResetService) -> Self {
    Self { dataContainer in
      await service.resetSandbox(at: dataContainer)
    }
  }
}
