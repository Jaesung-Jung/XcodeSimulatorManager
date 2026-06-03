import ComposableArchitecture
import MainWindowFeatureSupport
import WorkspaceFeature

// MARK: - MainWindowFeature Workspace Device Routing
extension MainWindowFeature {
  func routeWorkspaceDeviceAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.bootButtonTapped(let deviceID)):
      return runDeviceCommand(
        &state,
        DeviceCommandState(command: .boot, deviceID: deviceID)
      )

    case .deviceDetail(.shutdownButtonTapped(let deviceID)):
      return runDeviceCommand(
        &state,
        DeviceCommandState(command: .shutdown, deviceID: deviceID)
      )

    case .deviceDetail(.openSimulatorAppButtonTapped):
      return openSimulatorApp(&state)

    case .deviceDetail(.renameButtonTapped(let deviceID)):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let device = device(id: deviceID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .rename(
        RenameDeviceFormState(
          deviceID: device.id,
          currentName: device.name,
          name: device.name
        )
      )
      return .none

    case .deviceDetail(.eraseButtonTapped(let deviceID)):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = deviceDestructiveConfirmationState(
              deviceID: deviceID,
              in: state
            )
      else {
        return .none
      }

      state.lifecycleSheet = .erase(confirmationState)
      return .none

    case .deviceDetail(.deleteButtonTapped(let deviceID)):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = deviceDestructiveConfirmationState(
              deviceID: deviceID,
              in: state
            )
      else {
        return .none
      }

      state.lifecycleSheet = .delete(confirmationState)
      return .none

    case .deviceDetail(.unpairButtonTapped(let pairID)):
      guard state.workspace.deviceCommandState == nil,
            state.workspace.appCommandState == nil,
            let confirmationState = unpairConfirmationState(pairID: pairID, in: state)
      else {
        return .none
      }

      state.lifecycleSheet = .unpair(confirmationState)
      return .none

    default:
      return .none
    }
  }
}
