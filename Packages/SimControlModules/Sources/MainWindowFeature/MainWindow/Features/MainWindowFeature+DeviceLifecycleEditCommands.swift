import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows

// MARK: - MainWindowFeature Device Lifecycle Edit Commands

extension MainWindowFeature {
  func runCloneDeviceCommand(
    _ state: inout State,
    formState: CloneDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          device(id: formState.sourceDeviceID, in: state) != nil,
          let name = nonEmpty(formState.name)
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .clone,
      deviceID: formState.sourceDeviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.cloneDevice(
        formState.sourceDeviceID,
        name
      )
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

  func runRenameDeviceCommand(
    _ state: inout State,
    formState: RenameDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          device(id: formState.deviceID, in: state) != nil,
          let name = nonEmpty(formState.name),
          name != formState.currentName
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .rename,
      deviceID: formState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.renameDevice(
        formState.deviceID,
        name
      )
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
