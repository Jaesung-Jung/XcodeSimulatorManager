import ComposableArchitecture

// MARK: - MainWindowFeature Developer Tool Location Commands

extension MainWindowFeature {
  func runSetLocationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.setLocationDisabledReason == nil,
          let coordinate = tools.selectedLocationCoordinate,
          let normalizedCoordinate = normalizedCoordinate(coordinate)
    else {
      return .none
    }

    state.workspace.deviceDetail.developerTools.recordLocation(normalizedCoordinate)
    let coordinatePair = "\(normalizedCoordinate.latitude),\(normalizedCoordinate.longitude)"

    return runDeveloperToolCommand(
      &state,
      command: .setLocation
    ) { workflow, deviceID, deviceState in
      await workflow.setLocation(deviceID, deviceState, coordinatePair)
    }
  }

  func runClearLocationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.clearLocationDisabledReason == nil else {
      return .none
    }

    return runDeveloperToolCommand(
      &state,
      command: .clearLocation
    ) { workflow, deviceID, deviceState in
      await workflow.clearLocation(deviceID, deviceState)
    }
  }
}
