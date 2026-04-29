import ComposableArchitecture

struct CoreSimulatorServiceClient: Sendable {
  var openSimulatorApp: @Sendable () async -> CommandResult
}

extension CoreSimulatorServiceClient: DependencyKey {
  static var liveValue: CoreSimulatorServiceClient {
    let service = CoreSimulatorService()

    return CoreSimulatorServiceClient {
      await service.openSimulatorApp()
    }
  }
}

extension DependencyValues {
  var coreSimulatorService: CoreSimulatorServiceClient {
    get { self[CoreSimulatorServiceClient.self] }
    set { self[CoreSimulatorServiceClient.self] = newValue }
  }
}
