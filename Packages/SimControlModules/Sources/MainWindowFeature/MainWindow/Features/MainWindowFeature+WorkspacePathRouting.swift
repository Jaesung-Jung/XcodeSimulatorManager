import ComposableArchitecture
import WorkspaceFeature

// MARK: - MainWindowFeature Workspace Path Routing
extension MainWindowFeature {
  func routeWorkspacePathAction(
    _ action: WorkspaceFeature.Action,
    into state: inout State
  ) -> Effect<Action> {
    switch action {
    case .deviceDetail(.openDeviceDataFolderButtonTapped(let deviceID)),
         .inspector(.openDeviceDataFolderButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.dataPath },
        label: "device data folder",
        operation: .open
      )

    case .deviceDetail(.copyDeviceDataPathButtonTapped(let deviceID)),
         .inspector(.copyDeviceDataPathButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.dataPath },
        label: "device data path",
        operation: .copy
      )

    case .deviceDetail(.openDeviceLogFolderButtonTapped(let deviceID)),
         .inspector(.openDeviceLogFolderButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.logPath },
        label: "device log folder",
        operation: .open
      )

    case .deviceDetail(.copyDeviceLogPathButtonTapped(let deviceID)),
         .inspector(.copyDeviceLogPathButtonTapped(let deviceID)):
      return runDevicePathAction(
        &state,
        deviceID: deviceID,
        path: { $0.logPath },
        label: "device log path",
        operation: .copy
      )

    case .deviceDetail(.copyDeviceUDIDButtonTapped(let deviceID)),
         .inspector(.copyDeviceUDIDButtonTapped(let deviceID)):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.udid },
        label: "device UDID"
      )

    case .deviceDetail(.copyRuntimeIdentifierButtonTapped(let deviceID)),
         .inspector(.copyRuntimeIdentifierButtonTapped(let deviceID)):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.runtimeID },
        label: "runtime identifier"
      )

    case .deviceDetail(.copyDeviceTypeIdentifierButtonTapped(let deviceID)),
         .inspector(.copyDeviceTypeIdentifierButtonTapped(let deviceID)):
      return runDeviceValueCopyAction(
        &state,
        deviceID: deviceID,
        value: { $0.deviceTypeID },
        label: "device type identifier"
      )

    default:
      return .none
    }
  }
}
