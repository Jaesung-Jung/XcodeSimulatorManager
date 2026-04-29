import ComposableArchitecture

struct CoreSimulatorServiceClient: Sendable {
  var openSimulatorApp: @Sendable () async -> CommandResult
  var bootDevice: @Sendable (_ id: String) async -> CommandResult
  var shutdownDevice: @Sendable (_ id: String) async -> CommandResult
}

extension CoreSimulatorServiceClient: DependencyKey {
  static var liveValue: CoreSimulatorServiceClient {
    let service = CoreSimulatorService()

    return CoreSimulatorServiceClient(
      openSimulatorApp: {
        await service.openSimulatorApp()
      },
      bootDevice: { id in
        await service.bootDevice(id: id)
      },
      shutdownDevice: { id in
        await service.shutdownDevice(id: id)
      }
    )
  }
}

extension DependencyValues {
  var coreSimulatorService: CoreSimulatorServiceClient {
    get { self[CoreSimulatorServiceClient.self] }
    set { self[CoreSimulatorServiceClient.self] = newValue }
  }
}
