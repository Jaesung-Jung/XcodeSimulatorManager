import SimControlClients
import SimControlDomain

/// The command and refresh outputs produced by a device lifecycle workflow.
public struct DeviceLifecycleWorkflowResult: Equatable {
  public let commandResult: CommandResult
  public let refreshResult: SimulatorRefreshResult
  public let preferredSelectedDeviceID: SimulatorDevice.ID?

  /// Creates a device lifecycle workflow result.
  public init(
    commandResult: CommandResult,
    refreshResult: SimulatorRefreshResult,
    preferredSelectedDeviceID: SimulatorDevice.ID?
  ) {
    self.commandResult = commandResult
    self.refreshResult = refreshResult
    self.preferredSelectedDeviceID = preferredSelectedDeviceID
  }
}

/// Runs device lifecycle command sequences outside the reducer.
public struct DeviceLifecycleWorkflowClient: Sendable {
  public var bootDevice: @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult
  public var shutdownDevice: @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult
  public var createDevice: @Sendable (
    _ name: String,
    _ deviceTypeID: SimulatorDeviceType.ID,
    _ runtimeID: SimulatorRuntime.ID
  ) async -> DeviceLifecycleWorkflowResult
  public var cloneDevice: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ name: String
  ) async -> DeviceLifecycleWorkflowResult
  public var renameDevice: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ name: String
  ) async -> DeviceLifecycleWorkflowResult
  public var eraseDevice: @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult
  public var deleteDevice: @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult
  public var pairDevices: @Sendable (
    _ watchDeviceID: SimulatorDevice.ID,
    _ phoneDeviceID: SimulatorDevice.ID
  ) async -> DeviceLifecycleWorkflowResult
  public var unpairDevice: @Sendable (_ pairID: DevicePair.ID) async -> DeviceLifecycleWorkflowResult

  /// Creates a device lifecycle workflow from endpoint closures.
  public init(
    bootDevice: @escaping @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult,
    shutdownDevice: @escaping @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult,
    createDevice: @escaping @Sendable (
      _ name: String,
      _ deviceTypeID: SimulatorDeviceType.ID,
      _ runtimeID: SimulatorRuntime.ID
    ) async -> DeviceLifecycleWorkflowResult,
    cloneDevice: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ name: String
    ) async -> DeviceLifecycleWorkflowResult,
    renameDevice: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ name: String
    ) async -> DeviceLifecycleWorkflowResult,
    eraseDevice: @escaping @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult,
    deleteDevice: @escaping @Sendable (_ deviceID: SimulatorDevice.ID) async -> DeviceLifecycleWorkflowResult,
    pairDevices: @escaping @Sendable (
      _ watchDeviceID: SimulatorDevice.ID,
      _ phoneDeviceID: SimulatorDevice.ID
    ) async -> DeviceLifecycleWorkflowResult,
    unpairDevice: @escaping @Sendable (_ pairID: DevicePair.ID) async -> DeviceLifecycleWorkflowResult
  ) {
    self.bootDevice = bootDevice
    self.shutdownDevice = shutdownDevice
    self.createDevice = createDevice
    self.cloneDevice = cloneDevice
    self.renameDevice = renameDevice
    self.eraseDevice = eraseDevice
    self.deleteDevice = deleteDevice
    self.pairDevices = pairDevices
    self.unpairDevice = unpairDevice
  }
}

public extension DeviceLifecycleWorkflowClient {
  /// Creates a device lifecycle workflow backed by dependency clients.
  static func live(
    coreSimulatorService: CoreSimulatorClient,
    simulatorRepository: SimulatorRepositoryClient
  ) -> Self {
    Self(
      bootDevice: { deviceID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.bootDevice(deviceID)
        }
      },
      shutdownDevice: { deviceID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.shutdownDevice(deviceID)
        }
      },
      createDevice: { name, deviceTypeID, runtimeID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: preferredDeviceID
        ) {
          await coreSimulatorService.createDevice(name, deviceTypeID, runtimeID)
        }
      },
      cloneDevice: { deviceID, name in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: preferredDeviceID
        ) {
          await coreSimulatorService.cloneDevice(deviceID, name)
        }
      },
      renameDevice: { deviceID, name in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.renameDevice(deviceID, name)
        }
      },
      eraseDevice: { deviceID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.eraseDevice(deviceID)
        }
      },
      deleteDevice: { deviceID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.deleteDevice(deviceID)
        }
      },
      pairDevices: { watchDeviceID, phoneDeviceID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.pairDevices(watchDeviceID, phoneDeviceID)
        }
      },
      unpairDevice: { pairID in
        await runAndRefresh(
          simulatorRepository: simulatorRepository,
          preferredSelectedDeviceID: nil
        ) {
          await coreSimulatorService.unpairDevice(pairID)
        }
      }
    )
  }
}

private func runAndRefresh(
  simulatorRepository: SimulatorRepositoryClient,
  preferredSelectedDeviceID: ((CommandResult) -> SimulatorDevice.ID?)?,
  run: @escaping @Sendable () async -> CommandResult
) async -> DeviceLifecycleWorkflowResult {
  let commandResult = await run()
  let refreshResult = await simulatorRepository.refresh()

  return DeviceLifecycleWorkflowResult(
    commandResult: commandResult,
    refreshResult: refreshResult,
    preferredSelectedDeviceID: preferredSelectedDeviceID?(commandResult)
  )
}

private func preferredDeviceID(from result: CommandResult) -> SimulatorDevice.ID? {
  guard result.succeeded else {
    return nil
  }

  return result.stdout
    .split(whereSeparator: \.isNewline)
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .first { !$0.isEmpty }
}
