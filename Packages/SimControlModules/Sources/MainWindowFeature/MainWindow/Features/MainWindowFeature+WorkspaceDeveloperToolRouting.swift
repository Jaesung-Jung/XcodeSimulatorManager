import ComposableArchitecture
import WorkspaceFeature

// MARK: - MainWindowFeature Workspace Developer Tool Routing
extension MainWindowFeature {
  func routeWorkspaceDeveloperToolAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.developerTools(.openDeepLinkButtonTapped)):
      return runOpenDeepLinkCommand(&state)

    case .deviceDetail(.developerTools(.sendPushButtonTapped)):
      return runPushNotificationCommand(&state)

    case .deviceDetail(.developerTools(.applyPrivacyButtonTapped)):
      return runPrivacyPermissionCommand(&state)

    case .deviceDetail(.developerTools(.setLocationButtonTapped)):
      return runSetLocationCommand(&state)

    case .deviceDetail(.developerTools(.clearLocationButtonTapped)):
      return runClearLocationCommand(&state)

    case .deviceDetail(.developerTools(.setStatusBarOverrideButtonTapped)):
      return runSetStatusBarOverrideCommand(&state)

    case .deviceDetail(.developerTools(.clearStatusBarOverrideButtonTapped)):
      return runClearStatusBarOverrideCommand(&state)

    default:
      return .none
    }
  }
}
