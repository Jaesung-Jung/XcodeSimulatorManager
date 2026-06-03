import Foundation
import SimControlDomain

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

/// Confirmation payload for destructive simulator device commands.
public struct DeviceDestructiveConfirmationState: Equatable {
  public let deviceID: String
  public let deviceName: String
  public let deviceUDID: String

  /// Creates a confirmation payload for a destructive simulator device command.
  public init(deviceID: String, deviceName: String, deviceUDID: String) {
    self.deviceID = deviceID
    self.deviceName = deviceName
    self.deviceUDID = deviceUDID
  }
}

/// Form state used to create a simulator device.
public struct CreateDeviceFormState: Equatable {
  public var name: String
  public var runtimeID: String
  public var deviceTypeID: String

  /// Creates form state for a create-device sheet.
  public init(
    name: String = "",
    runtimeID: String = "",
    deviceTypeID: String = ""
  ) {
    self.name = name
    self.runtimeID = runtimeID
    self.deviceTypeID = deviceTypeID
  }
}

/// Form state used to clone a simulator device.
public struct CloneDeviceFormState: Equatable {
  public let sourceDeviceID: String
  public let sourceName: String
  public var name: String

  /// Creates form state for a clone-device sheet.
  public init(sourceDeviceID: String, sourceName: String, name: String) {
    self.sourceDeviceID = sourceDeviceID
    self.sourceName = sourceName
    self.name = name
  }
}

/// Form state used to rename a simulator device.
public struct RenameDeviceFormState: Equatable {
  public let deviceID: String
  public let currentName: String
  public var name: String

  /// Creates form state for a rename-device sheet.
  public init(deviceID: String, currentName: String, name: String) {
    self.deviceID = deviceID
    self.currentName = currentName
    self.name = name
  }
}

/// Candidate simulator device that can participate in a phone/watch pair.
public struct PairDeviceCandidate: Equatable, Identifiable {
  public let id: String
  public let name: String
  public let udid: String

  /// Creates a pairing candidate from a simulator device.
  public init(device: SimulatorDevice) {
    self.id = device.id
    self.name = device.name
    self.udid = device.udid
  }
}

/// Form state used to pair a phone simulator with a watch simulator.
public struct PairDevicesFormState: Equatable {
  public var phoneDeviceID: String
  public var watchDeviceID: String

  /// Creates form state for a pair-devices sheet.
  public init(phoneDeviceID: String, watchDeviceID: String) {
    self.phoneDeviceID = phoneDeviceID
    self.watchDeviceID = watchDeviceID
  }
}

/// Confirmation payload for unpairing a phone/watch simulator pair.
public struct UnpairDeviceConfirmationState: Equatable {
  public let pairID: String
  public let phoneName: String
  public let phoneUDID: String
  public let watchName: String
  public let watchUDID: String

  /// Creates a confirmation payload for unpairing a simulator pair.
  public init(
    pairID: String,
    phoneName: String,
    phoneUDID: String,
    watchName: String,
    watchUDID: String
  ) {
    self.pairID = pairID
    self.phoneName = phoneName
    self.phoneUDID = phoneUDID
    self.watchName = watchName
    self.watchUDID = watchUDID
  }
}

/// Confirmation payload for destructive installed app commands.
public struct AppDestructiveConfirmationState: Equatable {
  public let appID: String
  public let appName: String
  public let bundleID: String
  public let deviceID: String
  public let deviceName: String
  public let deviceUDID: String
  public let dataContainerPath: String?

  /// Creates a confirmation payload for a destructive installed app command.
  public init(
    appID: String,
    appName: String,
    bundleID: String,
    deviceID: String,
    deviceName: String,
    deviceUDID: String,
    dataContainerPath: String?
  ) {
    self.appID = appID
    self.appName = appName
    self.bundleID = bundleID
    self.deviceID = deviceID
    self.deviceName = deviceName
    self.deviceUDID = deviceUDID
    self.dataContainerPath = dataContainerPath
  }
}

/// Candidate simulator device that can receive an app install.
public struct InstallAppTargetCandidate: Equatable, Identifiable {
  public let id: String
  public let name: String
  public let udid: String
  public let state: SimulatorDevice.State

  /// Creates an install target candidate from a simulator device.
  public init(device: SimulatorDevice) {
    self.id = device.id
    self.name = device.name
    self.udid = device.udid
    self.state = device.state
  }
}

/// Form state used to install an app bundle on another simulator.
public struct InstallAppTargetFormState: Equatable {
  public let sourceAppID: String
  public let sourceDeviceID: String
  public let appName: String
  public let bundleID: String
  public let appBundlePath: URL
  public var targetDeviceID: String
  public var launchAfterInstall: Bool

  /// Creates form state for an install-app sheet.
  public init(
    sourceAppID: String,
    sourceDeviceID: String,
    appName: String,
    bundleID: String,
    appBundlePath: URL,
    targetDeviceID: String,
    launchAfterInstall: Bool
  ) {
    self.sourceAppID = sourceAppID
    self.sourceDeviceID = sourceDeviceID
    self.appName = appName
    self.bundleID = bundleID
    self.appBundlePath = appBundlePath
    self.targetDeviceID = targetDeviceID
    self.launchAfterInstall = launchAfterInstall
  }
}
