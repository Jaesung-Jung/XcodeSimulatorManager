import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

// MARK: - MainWindowFeature Device Lifecycle

extension MainWindowFeature {
  func runDeviceCommand(
    _ state: inout State,
    _ deviceCommandState: DeviceCommandState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let deviceID = deviceCommandState.deviceID,
          let device = device(id: deviceID, in: state),
          canRun(deviceCommandState.command, on: device)
    else {
      return .none
    }

    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result: DeviceLifecycleWorkflowResult

      switch deviceCommandState.command {
      case .boot:
        result = await workflow.bootDevice(deviceID)
      case .shutdown:
        result = await workflow.shutdownDevice(deviceID)
      case .create,
           .clone,
           .rename,
           .erase,
           .delete,
           .pair,
           .unpair,
           .openURL,
           .pushNotification,
           .privacyPermission,
           .setLocation,
           .clearLocation,
           .statusBarOverride,
           .clearStatusBarOverride:
        return
      }

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

  func runCreateDeviceCommand(
    _ state: inout State,
    formState: CreateDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let snapshot = state.workspace.snapshot,
          let runtime = snapshot.runtimes.first(where: { $0.id == formState.runtimeID && $0.isAvailable }),
          let deviceType = compatibleDeviceTypes(for: runtime, in: snapshot.deviceTypes)
            .first(where: { $0.id == formState.deviceTypeID })
    else {
      return .none
    }

    let name = nonEmpty(formState.name) ?? deviceType.name
    guard !name.isEmpty else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .create)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.createDevice(
        name,
        deviceType.id,
        runtime.id
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

  func runPairDevicesCommand(
    _ state: inout State,
    formState: PairDevicesFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          state.pairPhoneCandidates.contains(where: { $0.id == formState.phoneDeviceID }),
          state.pairWatchCandidates.contains(where: { $0.id == formState.watchDeviceID })
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .pair)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.pairDevices(
        formState.watchDeviceID,
        formState.phoneDeviceID
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

  func runUnpairDeviceCommand(
    _ state: inout State,
    confirmationState: UnpairDeviceConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          unpairConfirmationState(pairID: confirmationState.pairID, in: state) == confirmationState
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .unpair)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let workflow = DeviceLifecycleWorkflowClient.live(
        coreSimulatorService: coreSimulatorService,
        simulatorRepository: simulatorRepository
      )
      let result = await workflow.unpairDevice(confirmationState.pairID)
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
