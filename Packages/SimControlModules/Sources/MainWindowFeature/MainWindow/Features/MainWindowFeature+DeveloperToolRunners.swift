import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature Developer Tool Runners

extension MainWindowFeature {
  func runDeveloperToolCommand(
    _ state: inout State,
    command: DeviceCommand,
    run: @escaping @Sendable (
      DeveloperToolWorkflowClient,
      SimulatorDevice.ID,
      SimulatorDevice.State
    ) async -> DeveloperToolWorkflowResult
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = state.workspace.selectedDevice,
          device.isAvailable,
          device.state == .booted || device.state == .shutdown
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: command, deviceID: device.id)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeveloperToolWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await run(workflow, device.id, device.state)
      await send(
        .developerToolCommandResults(
          deviceCommandState,
          result.commandResults,
          refreshAfterward: result.refreshResult != nil
        )
      )

      if let refreshResult = result.refreshResult {
        await send(
          .developerToolCommandRefreshResponse(
            deviceCommandState,
            refreshResult,
            preferredSelectedDeviceID: result.preferredSelectedDeviceID
          )
        )
      }
    }
  }

  func runBootedDeveloperToolCommand(
    _ state: inout State,
    command: DeviceCommand,
    run: @escaping @Sendable (
      DeveloperToolWorkflowClient,
      SimulatorDevice.ID
    ) async -> DeveloperToolWorkflowResult
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = state.workspace.selectedDevice,
          device.isAvailable,
          device.state == .booted
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: command, deviceID: device.id)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeveloperToolWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await run(workflow, device.id)
      await send(
        .developerToolCommandResults(
          deviceCommandState,
          result.commandResults,
          refreshAfterward: result.refreshResult != nil
        )
      )

      if let refreshResult = result.refreshResult {
        await send(
          .developerToolCommandRefreshResponse(
            deviceCommandState,
            refreshResult,
            preferredSelectedDeviceID: result.preferredSelectedDeviceID
          )
        )
      }
    }
  }
}
