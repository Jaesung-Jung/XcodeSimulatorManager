import ComposableArchitecture

struct CoreSimulatorServiceClient: Sendable {
  var openSimulatorApp: @Sendable () async -> CommandResult
  var bootDevice: @Sendable (_ id: String) async -> CommandResult
  var shutdownDevice: @Sendable (_ id: String) async -> CommandResult
  var createDevice: @Sendable (_ name: String, _ deviceTypeID: String, _ runtimeID: String) async -> CommandResult
  var cloneDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult
  var renameDevice: @Sendable (_ id: String, _ name: String) async -> CommandResult
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
      },
      createDevice: { name, deviceTypeID, runtimeID in
        await service.createDevice(
          name: name,
          deviceTypeID: deviceTypeID,
          runtimeID: runtimeID
        )
      },
      cloneDevice: { id, name in
        await service.cloneDevice(id: id, name: name)
      },
      renameDevice: { id, name in
        await service.renameDevice(id: id, name: name)
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
