import Foundation
import ComposableArchitecture
import SimControlDomain
import SimControlInfrastructure

/// A TCA dependency boundary for destructive app sandbox reset operations.
public struct AppSandboxResetClient: Sendable {
  public var resetSandbox: @Sendable (_ dataContainer: URL) async -> CommandResult

  /// Creates an app sandbox reset client from a reset endpoint.
  public init(resetSandbox: @escaping @Sendable (_ dataContainer: URL) async -> CommandResult) {
    self.resetSandbox = resetSandbox
  }
}

extension AppSandboxResetClient: DependencyKey {
  public static var liveValue: AppSandboxResetClient {
    let service = AppSandboxResetService()

    return AppSandboxResetClient { dataContainer in
      await service.resetSandbox(at: dataContainer)
    }
  }
}

extension DependencyValues {
  /// The injected app sandbox reset client.
  public var appSandboxReset: AppSandboxResetClient {
    get { self[AppSandboxResetClient.self] }
    set { self[AppSandboxResetClient.self] = newValue }
  }
}
