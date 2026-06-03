import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows

// MARK: - MainWindowFeature Device Destructive Commands
extension MainWindowFeature {
  func runEraseDeviceCommand(
    _ state: inout State,
    confirmationState: DeviceDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = device(id: confirmationState.deviceID, in: state),
          device.isAvailable,
          device.udid == confirmationState.deviceUDID
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .erase,
      deviceID: confirmationState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.eraseDevice(confirmationState.deviceID)
      await send(.deviceCommandResponse(deviceCommandState, result.commandResult))

      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID
        )
      )
    }
  }

  func runDeleteDeviceCommand(
    _ state: inout State,
    confirmationState: DeviceDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = device(id: confirmationState.deviceID, in: state),
          device.udid == confirmationState.deviceUDID
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .delete,
      deviceID: confirmationState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.deleteDevice(confirmationState.deviceID)
      await send(.deviceCommandResponse(deviceCommandState, result.commandResult))

      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          result.refreshResult,
          preferredSelectedDeviceID: result.preferredSelectedDeviceID
        )
      )
    }
  }
}
