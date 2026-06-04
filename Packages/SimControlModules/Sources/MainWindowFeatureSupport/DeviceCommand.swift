/// Device-level commands that can be routed from the UI to workflow execution.
public enum DeviceCommand {
  case boot
  case shutdown
  case create
  case clone
  case rename
  case erase
  case delete
  case pair
  case unpair
  case openURL
  case remoteNotification
  case privacyPermission
  case setLocation
  case clearLocation
  case statusBarOverride
  case clearStatusBarOverride
}
