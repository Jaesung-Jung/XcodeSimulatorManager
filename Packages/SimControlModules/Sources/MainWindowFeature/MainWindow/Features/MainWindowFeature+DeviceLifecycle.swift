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

    return .run { [deviceLifecycleWorkflow] send in
      let result: DeviceLifecycleWorkflowResult

      switch deviceCommandState.command {
      case .boot:
        result = await deviceLifecycleWorkflow.bootDevice(deviceID)
      case .shutdown:
        result = await deviceLifecycleWorkflow.shutdownDevice(deviceID)
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

}

// MARK: - MainWindowFeature Device Creation Commands

extension MainWindowFeature {
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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.createDevice(
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
}

// MARK: - MainWindowFeature Device Lookup and Validation

extension MainWindowFeature {
  func device(id: String, in state: State) -> SimulatorDevice? {
    state.workspace.snapshot?.devices.first { $0.id == id }
  }

  func deviceDestructiveConfirmationState(
    deviceID: String,
    in state: State
  ) -> DeviceDestructiveConfirmationState? {
    guard let device = device(id: deviceID, in: state) else {
      return nil
    }

    return DeviceDestructiveConfirmationState(
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid
    )
  }

  func unpairConfirmationState(
    pairID: String,
    in state: State
  ) -> UnpairDeviceConfirmationState? {
    guard let snapshot = state.workspace.snapshot,
          let pair = snapshot.pairs.first(where: { $0.id == pairID }),
          let phoneDevice = snapshot.devices.first(where: { $0.id == pair.phoneDeviceID }),
          let watchDevice = snapshot.devices.first(where: { $0.id == pair.watchDeviceID })
    else {
      return nil
    }

    return UnpairDeviceConfirmationState(
      pairID: pair.id,
      phoneName: phoneDevice.name,
      phoneUDID: phoneDevice.udid,
      watchName: watchDevice.name,
      watchUDID: watchDevice.udid
    )
  }

  func canRun(
    _ command: DeviceCommand,
    on device: SimulatorDevice
  ) -> Bool {
    guard device.isAvailable else {
      return false
    }

    switch command {
    case .boot:
      return device.state == .shutdown
    case .shutdown:
      return device.state == .booted
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
      return false
    }
  }

  func compatibleDeviceTypes(
    for runtime: SimulatorRuntime,
    in deviceTypes: [SimulatorDeviceType]
  ) -> [SimulatorDeviceType] {
    guard !runtime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }
}

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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.cloneDevice(
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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.renameDevice(
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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.eraseDevice(confirmationState.deviceID)
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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.deleteDevice(confirmationState.deviceID)
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

// MARK: - MainWindowFeature Device Pairing Commands

extension MainWindowFeature {
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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.pairDevices(
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

    return .run { [deviceLifecycleWorkflow] send in
      let result = await deviceLifecycleWorkflow.unpairDevice(confirmationState.pairID)
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
