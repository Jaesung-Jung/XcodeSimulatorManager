import ComposableArchitecture
import SimControlDomain
import SimControlInfrastructure
import Foundation

struct AppSandboxResetClient: Sendable {
  var resetSandbox: @Sendable (_ dataContainer: URL) async -> CommandResult
}

extension AppSandboxResetClient: DependencyKey {
  static var liveValue: AppSandboxResetClient {
    let service = AppSandboxResetService()

    return AppSandboxResetClient { dataContainer in
      await service.resetSandbox(at: dataContainer)
    }
  }
}

extension DependencyValues {
  var appSandboxReset: AppSandboxResetClient {
    get { self[AppSandboxResetClient.self] }
    set { self[AppSandboxResetClient.self] = newValue }
  }
}
