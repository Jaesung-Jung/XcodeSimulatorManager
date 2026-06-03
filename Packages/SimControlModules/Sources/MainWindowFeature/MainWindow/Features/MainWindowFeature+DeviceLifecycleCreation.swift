import ComposableArchitecture
import MainWindowFeatureSupport
import MainWindowWorkflows
import SimControlDomain

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
