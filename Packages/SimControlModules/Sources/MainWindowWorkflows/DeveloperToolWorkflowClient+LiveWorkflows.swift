import SimControlClients
import SimControlDomain

func runBootableDeveloperToolCommand(
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

func runBootedDeveloperToolCommand(
  run: @escaping @Sendable () async -> CommandResult
) async -> DeveloperToolWorkflowResult {
  DeveloperToolWorkflowResult(
    commandResults: [await run()],
    refreshResult: nil,
    preferredSelectedDeviceID: nil
  )
}

func refreshDeveloperToolResult(
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
