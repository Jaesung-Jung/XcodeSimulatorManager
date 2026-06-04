import SimControlClients
import SimControlDomain

func runAndRefresh(
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

func preferredDeviceID(from result: CommandResult) -> SimulatorDevice.ID? {
  guard result.succeeded else {
    return nil
  }

  return result.stdout
    .split(whereSeparator: \.isNewline)
    .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
    .first { !$0.isEmpty }
}
