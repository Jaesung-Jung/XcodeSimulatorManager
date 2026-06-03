import SimControlClients
import SimControlDomain

/// The command and optional refresh outputs produced by a developer tool workflow.
public struct DeveloperToolWorkflowResult: Equatable {
  public let commandResults: [CommandResult]
  public let refreshResult: SimulatorRefreshResult?
  public let preferredSelectedDeviceID: SimulatorDevice.ID?

  /// Creates a developer tool workflow result.
  public init(
    commandResults: [CommandResult],
    refreshResult: SimulatorRefreshResult?,
    preferredSelectedDeviceID: SimulatorDevice.ID?
  ) {
    self.commandResults = commandResults
    self.refreshResult = refreshResult
    self.preferredSelectedDeviceID = preferredSelectedDeviceID
  }
}

/// Runs developer tool command sequences outside the reducer.
public struct DeveloperToolWorkflowClient: Sendable {
  public var openURL: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ deviceState: SimulatorDevice.State,
    _ urlString: String
  ) async -> DeveloperToolWorkflowResult
  public var pushNotification: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ deviceState: SimulatorDevice.State,
    _ bundleID: String?,
    _ payloadJSON: String
  ) async -> DeveloperToolWorkflowResult
  public var setPrivacyPermission: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ deviceState: SimulatorDevice.State,
    _ action: String,
    _ service: String,
    _ bundleID: String?
  ) async -> DeveloperToolWorkflowResult
  public var setLocation: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ deviceState: SimulatorDevice.State,
    _ coordinate: String
  ) async -> DeveloperToolWorkflowResult
  public var clearLocation: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ deviceState: SimulatorDevice.State
  ) async -> DeveloperToolWorkflowResult
  public var setStatusBarOverride: @Sendable (
    _ deviceID: SimulatorDevice.ID,
    _ arguments: [String]
  ) async -> DeveloperToolWorkflowResult
  public var clearStatusBarOverride: @Sendable (
    _ deviceID: SimulatorDevice.ID
  ) async -> DeveloperToolWorkflowResult

  /// Creates a developer tool workflow from endpoint closures.
  public init(
    openURL: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ deviceState: SimulatorDevice.State,
      _ urlString: String
    ) async -> DeveloperToolWorkflowResult,
    pushNotification: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ deviceState: SimulatorDevice.State,
      _ bundleID: String?,
      _ payloadJSON: String
    ) async -> DeveloperToolWorkflowResult,
    setPrivacyPermission: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ deviceState: SimulatorDevice.State,
      _ action: String,
      _ service: String,
      _ bundleID: String?
    ) async -> DeveloperToolWorkflowResult,
    setLocation: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ deviceState: SimulatorDevice.State,
      _ coordinate: String
    ) async -> DeveloperToolWorkflowResult,
    clearLocation: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ deviceState: SimulatorDevice.State
    ) async -> DeveloperToolWorkflowResult,
    setStatusBarOverride: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID,
      _ arguments: [String]
    ) async -> DeveloperToolWorkflowResult,
    clearStatusBarOverride: @escaping @Sendable (
      _ deviceID: SimulatorDevice.ID
    ) async -> DeveloperToolWorkflowResult
  ) {
    self.openURL = openURL
    self.pushNotification = pushNotification
    self.setPrivacyPermission = setPrivacyPermission
    self.setLocation = setLocation
    self.clearLocation = clearLocation
    self.setStatusBarOverride = setStatusBarOverride
    self.clearStatusBarOverride = clearStatusBarOverride
  }
}

public extension DeveloperToolWorkflowClient {
  /// Creates a developer tool workflow backed by dependency clients.
  static func live(
    coreSimulatorService: CoreSimulatorClient,
    simulatorRepository: SimulatorRepositoryClient
  ) -> Self {
    Self(
      openURL: { deviceID, deviceState, urlString in
        await runBootableDeveloperToolCommand(
          deviceID: deviceID,
          deviceState: deviceState,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        ) {
          await coreSimulatorService.openURL(deviceID, urlString)
        }
      },
      pushNotification: { deviceID, deviceState, bundleID, payloadJSON in
        await runBootableDeveloperToolCommand(
          deviceID: deviceID,
          deviceState: deviceState,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        ) {
          await coreSimulatorService.pushNotification(
            deviceID,
            bundleID,
            payloadJSON
          )
        }
      },
      setPrivacyPermission: { deviceID, deviceState, action, service, bundleID in
        await runBootableDeveloperToolCommand(
          deviceID: deviceID,
          deviceState: deviceState,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        ) {
          await coreSimulatorService.setPrivacyPermission(
            deviceID,
            action,
            service,
            bundleID
          )
        }
      },
      setLocation: { deviceID, deviceState, coordinate in
        await runBootableDeveloperToolCommand(
          deviceID: deviceID,
          deviceState: deviceState,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        ) {
          await coreSimulatorService.setLocation(deviceID, coordinate)
        }
      },
      clearLocation: { deviceID, deviceState in
        await runBootableDeveloperToolCommand(
          deviceID: deviceID,
          deviceState: deviceState,
          coreSimulatorService: coreSimulatorService,
          simulatorRepository: simulatorRepository
        ) {
          await coreSimulatorService.clearLocation(deviceID)
        }
      },
      setStatusBarOverride: { deviceID, arguments in
        await runBootedDeveloperToolCommand {
          await coreSimulatorService.setStatusBarOverride(deviceID, arguments)
        }
      },
      clearStatusBarOverride: { deviceID in
        await runBootedDeveloperToolCommand {
          await coreSimulatorService.clearStatusBarOverride(deviceID)
        }
      }
    )
  }
}

private func runBootableDeveloperToolCommand(
  deviceID: SimulatorDevice.ID,
  deviceState: SimulatorDevice.State,
  coreSimulatorService: CoreSimulatorClient,
  simulatorRepository: SimulatorRepositoryClient,
  run: @escaping @Sendable () async -> CommandResult
) async -> DeveloperToolWorkflowResult {
  var commandResults: [CommandResult] = []
  let shouldBoot = deviceState == .shutdown

  if shouldBoot {
    let bootResult = await coreSimulatorService.bootDeviceIfNeeded(deviceID)
    commandResults.append(bootResult)

    guard bootResult.succeeded else {
      return await refreshDeveloperToolResult(
        commandResults: commandResults,
        simulatorRepository: simulatorRepository,
        preferredSelectedDeviceID: deviceID
      )
    }
  }

  commandResults.append(await run())

  guard shouldBoot else {
    return DeveloperToolWorkflowResult(
      commandResults: commandResults,
      refreshResult: nil,
      preferredSelectedDeviceID: nil
    )
  }

  return await refreshDeveloperToolResult(
    commandResults: commandResults,
    simulatorRepository: simulatorRepository,
    preferredSelectedDeviceID: deviceID
  )
}

private func runBootedDeveloperToolCommand(
  run: @escaping @Sendable () async -> CommandResult
) async -> DeveloperToolWorkflowResult {
  DeveloperToolWorkflowResult(
    commandResults: [await run()],
    refreshResult: nil,
    preferredSelectedDeviceID: nil
  )
}

private func refreshDeveloperToolResult(
  commandResults: [CommandResult],
  simulatorRepository: SimulatorRepositoryClient,
  preferredSelectedDeviceID: SimulatorDevice.ID
) async -> DeveloperToolWorkflowResult {
  DeveloperToolWorkflowResult(
    commandResults: commandResults,
    refreshResult: await simulatorRepository.refresh(),
    preferredSelectedDeviceID: preferredSelectedDeviceID
  )
}
