import ComposableArchitecture

// MARK: - MainWindowFeature Sheet Routing
extension MainWindowFeature {
  func routeSheetAction(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case .createSimulatorButtonTapped:
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let formState = state.initialCreateDeviceFormState
      else {
        return .none
      }

      state.lifecycleSheet = .create(formState)
      return .none

    case .cloneSelectedSimulatorButtonTapped:
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let device = state.workspace.selectedDevice
      else {
        return .none
      }

      state.lifecycleSheet = .clone(
        CloneDeviceFormState(
          sourceDeviceID: device.id,
          sourceName: device.name,
          name: "\(device.name) Copy"
        )
      )
      return .none

    case .pairDevicesButtonTapped:
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let formState = state.initialPairDevicesFormState
      else {
        return .none
      }

      state.lifecycleSheet = .pair(formState)
      return .none

    case .lifecycleSheetDismissed:
      state.lifecycleSheet = nil
      return .none

    case .createDeviceSubmitted(let formState):
      state.lifecycleSheet = nil
      return runCreateDeviceCommand(&state, formState: formState)

    case .cloneDeviceSubmitted(let formState):
      state.lifecycleSheet = nil
      return runCloneDeviceCommand(&state, formState: formState)

    case .renameDeviceSubmitted(let formState):
      state.lifecycleSheet = nil
      return runRenameDeviceCommand(&state, formState: formState)

    case .eraseDeviceConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runEraseDeviceCommand(&state, confirmationState: confirmationState)

    case .deleteDeviceConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runDeleteDeviceCommand(&state, confirmationState: confirmationState)

    case .pairDevicesSubmitted(let formState):
      state.lifecycleSheet = nil
      return runPairDevicesCommand(&state, formState: formState)

    case .unpairDeviceConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runUnpairDeviceCommand(&state, confirmationState: confirmationState)

    case .uninstallAppConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runUninstallAppCommand(&state, confirmationState: confirmationState)

    case .resetAppSandboxConfirmed(let confirmationState):
      state.lifecycleSheet = nil
      return runResetAppSandboxCommand(&state, confirmationState: confirmationState)

    case .installAppOnSimulatorSubmitted(let formState):
      state.lifecycleSheet = nil
      return runInstallAppOnSimulatorCommand(&state, formState: formState)

    default:
      return .none
    }
  }
}
