import ComposableArchitecture
import DeveloperToolsFeature

// MARK: - MainWindowFeature Developer Tools

extension MainWindowFeature {
  func runOpenDeepLinkCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.openDeepLinkDisabledReason == nil else {
      return .none
    }

    let urlString = DeveloperToolsFeature.State.trimmed(tools.deepLinkURLString)
    state.workspace.deviceDetail.developerTools.recordDeepLinkURL(urlString)

    return runDeveloperToolCommand(
      &state,
      command: .openURL
    ) { workflow, deviceID, deviceState in
      await workflow.openURL(deviceID, deviceState, urlString)
    }
  }

  func runPushNotificationCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.sendPushDisabledReason == nil else {
      return .none
    }

    let bundleID = nonEmpty(tools.pushBundleID)
    let payloadJSON = tools.pushPayloadJSON

    return runDeveloperToolCommand(
      &state,
      command: .pushNotification
    ) { workflow, deviceID, deviceState in
      await workflow.pushNotification(
        deviceID,
        deviceState,
        bundleID,
        payloadJSON
      )
    }
  }

  func runPrivacyPermissionCommand(_ state: inout State) -> Effect<Action> {
    let tools = state.workspace.deviceDetail.developerTools
    guard tools.applyPrivacyDisabledReason == nil else {
      return .none
    }

    let action = tools.privacyAction.rawValue
    let service = tools.privacyService.simctlArgument
    let bundleID = nonEmpty(tools.privacyBundleID)

    return runDeveloperToolCommand(
      &state,
      command: .privacyPermission
    ) { workflow, deviceID, deviceState in
      await workflow.setPrivacyPermission(
        deviceID,
        deviceState,
        action,
        service,
        bundleID
      )
    }
  }
}
