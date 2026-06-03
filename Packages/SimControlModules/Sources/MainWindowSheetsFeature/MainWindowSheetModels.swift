/// Describes the modal sheet currently presented by the main window.
public enum DeviceLifecycleSheet: Equatable, Identifiable {
  case create(CreateDeviceFormState)
  case clone(CloneDeviceFormState)
  case rename(RenameDeviceFormState)
  case erase(DeviceDestructiveConfirmationState)
  case delete(DeviceDestructiveConfirmationState)
  case pair(PairDevicesFormState)
  case unpair(UnpairDeviceConfirmationState)
  case uninstallApp(AppDestructiveConfirmationState)
  case resetAppSandbox(AppDestructiveConfirmationState)
  case installAppOnSimulator(InstallAppTargetFormState)

  public var id: String {
    switch self {
    case .create:
      "create"
    case .clone(let formState):
      "clone-\(formState.sourceDeviceID)"
    case .rename(let formState):
      "rename-\(formState.deviceID)"
    case .erase(let confirmationState):
      "erase-\(confirmationState.deviceID)"
    case .delete(let confirmationState):
      "delete-\(confirmationState.deviceID)"
    case .pair:
      "pair"
    case .unpair(let confirmationState):
      "unpair-\(confirmationState.pairID)"
    case .uninstallApp(let confirmationState):
      "uninstall-app-\(confirmationState.appID)"
    case .resetAppSandbox(let confirmationState):
      "reset-app-sandbox-\(confirmationState.appID)"
    case .installAppOnSimulator(let formState):
      "install-app-\(formState.sourceAppID)"
    }
  }
}
