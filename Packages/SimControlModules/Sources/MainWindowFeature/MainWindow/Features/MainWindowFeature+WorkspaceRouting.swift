import ComposableArchitecture
import WorkspaceFeature

// MARK: - MainWindowFeature Workspace Routing
extension MainWindowFeature {
  func routeWorkspaceAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.bootButtonTapped),
         .deviceDetail(.shutdownButtonTapped),
         .deviceDetail(.openSimulatorAppButtonTapped),
         .deviceDetail(.renameButtonTapped),
         .deviceDetail(.eraseButtonTapped),
         .deviceDetail(.deleteButtonTapped),
         .deviceDetail(.unpairButtonTapped):
      return routeWorkspaceDeviceAction(action, into: &state)

    case .deviceDetail(.openDeviceDataFolderButtonTapped),
         .deviceDetail(.copyDeviceDataPathButtonTapped),
         .deviceDetail(.openDeviceLogFolderButtonTapped),
         .deviceDetail(.copyDeviceLogPathButtonTapped),
         .deviceDetail(.copyDeviceUDIDButtonTapped),
         .deviceDetail(.copyRuntimeIdentifierButtonTapped),
         .deviceDetail(.copyDeviceTypeIdentifierButtonTapped),
         .inspector(.openDeviceDataFolderButtonTapped),
         .inspector(.copyDeviceDataPathButtonTapped),
         .inspector(.openDeviceLogFolderButtonTapped),
         .inspector(.copyDeviceLogPathButtonTapped),
         .inspector(.copyDeviceUDIDButtonTapped),
         .inspector(.copyRuntimeIdentifierButtonTapped),
         .inspector(.copyDeviceTypeIdentifierButtonTapped):
      return routeWorkspacePathAction(action, into: &state)

    case .deviceDetail(.installedApps),
         .inspector(.openAppBundleContainerButtonTapped),
         .inspector(.copyAppBundleContainerButtonTapped),
         .inspector(.openAppDataContainerButtonTapped),
         .inspector(.copyAppDataContainerButtonTapped),
         .inspector(.copyAppBundleIDButtonTapped),
         .inspector(.openAppGroupContainerButtonTapped),
         .inspector(.copyAppGroupContainerButtonTapped):
      return routeWorkspaceInstalledAppAction(action, into: &state)

    case .deviceDetail(.developerTools):
      return routeWorkspaceDeveloperToolAction(action, into: &state)

    default:
      return .none
    }
  }
}
