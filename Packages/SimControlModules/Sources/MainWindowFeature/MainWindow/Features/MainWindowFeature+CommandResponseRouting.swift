import ComposableArchitecture

// MARK: - MainWindowFeature Command Response Routing
extension MainWindowFeature {
  func routeCommandResponseAction(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case .pathActionResults(let results):
      return routePathActionResults(results, into: &state)

    case .developerToolCommandResults(let deviceCommandState, let results, let refreshAfterward):
      return routeDeveloperToolCommandResults(
        deviceCommandState,
        results,
        refreshAfterward: refreshAfterward,
        into: &state
      )

    case .developerToolCommandRefreshResponse(
      let deviceCommandState,
      let result,
      let preferredSelectedDeviceID
    ):
      return routeDeveloperToolCommandRefreshResponse(
        deviceCommandState,
        result,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        into: &state
      )

    case .deviceCommandResponse(let deviceCommandState, let result):
      return routeDeviceCommandResponse(deviceCommandState, result, into: &state)

    case .deviceCommandRefreshResponse(let deviceCommandState, let result, let preferredSelectedDeviceID):
      return routeDeviceCommandRefreshResponse(
        deviceCommandState,
        result,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        into: &state
      )

    case .appCommandCommandsCompleted(
      let appCommandState,
      let commandResults,
      preferredSelectedDeviceID: _,
      preferredSelectedAppID: _
    ):
      return routeAppCommandCommandsCompleted(
        appCommandState,
        commandResults,
        into: &state
      )

    case .appCommandRefreshResponse(
      let appCommandState,
      let result,
      let preferredSelectedDeviceID,
      let preferredSelectedAppID
    ):
      return routeAppCommandRefreshResponse(
        appCommandState,
        result,
        preferredSelectedDeviceID: preferredSelectedDeviceID,
        preferredSelectedAppID: preferredSelectedAppID,
        into: &state
      )

    default:
      return .none
    }
  }
}
