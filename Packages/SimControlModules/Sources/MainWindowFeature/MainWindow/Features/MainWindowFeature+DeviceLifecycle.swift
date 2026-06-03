import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows

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
