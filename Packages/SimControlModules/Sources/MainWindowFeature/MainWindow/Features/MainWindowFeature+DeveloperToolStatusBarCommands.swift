import ComposableArchitecture

// MARK: - MainWindowFeature Developer Tool Status Bar Commands

extension MainWindowFeature {
  func runSetStatusBarOverrideCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.setStatusBarOverrideDisabledReason == nil else {
      return .none
    }

    let arguments = tools.statusBarOverrideArguments

    return runBootedDeveloperToolCommand(
      &state,
      command: .statusBarOverride
    ) { workflow, deviceID in
      await workflow.setStatusBarOverride(deviceID, arguments)
    }
  }

  func runClearStatusBarOverrideCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.clearStatusBarOverrideDisabledReason == nil else {
      return .none
    }

    return runBootedDeveloperToolCommand(
      &state,
      command: .clearStatusBarOverride
    ) { workflow, deviceID in
      await workflow.clearStatusBarOverride(deviceID)
    }
  }
}
