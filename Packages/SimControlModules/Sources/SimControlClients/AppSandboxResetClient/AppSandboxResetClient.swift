import Foundation
import Dependencies
import SimControlDomain

/// A TCA dependency boundary for destructive app sandbox reset operations.
public struct AppSandboxResetClient: Sendable {
  /// Resets the contents of an app data container.
  public var resetSandbox: @Sendable (_ dataContainer: URL) async -> CommandResult

  /// Creates an app sandbox reset client from a reset endpoint.
  public init(resetSandbox: @escaping @Sendable (_ dataContainer: URL) async -> CommandResult) {
    self.resetSandbox = resetSandbox
  }
}

extension AppSandboxResetClient: TestDependencyKey {
  /// An unimplemented client used by dependency tests unless overridden.
  public static let testValue = AppSandboxResetClient(
    resetSandbox: unimplemented(
      "AppSandboxResetClient.resetSandbox",
      placeholder: placeholderCommandResult("AppSandboxResetClient.resetSandbox")
    )
  )
}

extension DependencyValues {
  /// The injected app sandbox reset client.
  public var appSandboxReset: AppSandboxResetClient {
    get { self[AppSandboxResetClient.self] }
    set { self[AppSandboxResetClient.self] = newValue }
  }
}
