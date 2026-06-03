import Foundation
import SimControlDomain

// MARK: - MainWindowFeature.AppContainerPathTarget
extension MainWindowFeature {
  enum AppContainerPathTarget: Equatable, Sendable {
    case bundle
    case data
    case appGroup(String)

    var simctlContainer: SimulatorAppContainerKind {
      switch self {
      case .bundle:
        .app
      case .data:
        .data
      case .appGroup(let groupID):
        .appGroup(groupID)
      }
    }

    var label: String {
      switch self {
      case .bundle:
        "app bundle container"
      case .data:
        "app data container"
      case .appGroup(let groupID):
        "App Group \(groupID) container"
      }
    }
  }
}

// MARK: - MainWindowFeature.DeviceLifecycleSheet
extension MainWindowFeature {
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
}

// MARK: - MainWindowFeature.DeviceDestructiveConfirmationState
extension MainWindowFeature {
  public struct DeviceDestructiveConfirmationState: Equatable {
    let deviceID: String
    let deviceName: String
    let deviceUDID: String
  }
}

// MARK: - MainWindowFeature.CreateDeviceFormState
extension MainWindowFeature {
  public struct CreateDeviceFormState: Equatable {
    var name: String
    var runtimeID: String
    var deviceTypeID: String

    init(
      name: String = "",
      runtimeID: String = "",
      deviceTypeID: String = ""
    ) {
      self.name = name
      self.runtimeID = runtimeID
      self.deviceTypeID = deviceTypeID
    }
  }
}

// MARK: - MainWindowFeature.CloneDeviceFormState
extension MainWindowFeature {
  public struct CloneDeviceFormState: Equatable {
    let sourceDeviceID: String
    let sourceName: String
    var name: String
  }
}

// MARK: - MainWindowFeature.RenameDeviceFormState
extension MainWindowFeature {
  public struct RenameDeviceFormState: Equatable {
    let deviceID: String
    let currentName: String
    var name: String
  }
}

// MARK: - MainWindowFeature.PairDeviceCandidate
extension MainWindowFeature {
  public struct PairDeviceCandidate: Equatable, Identifiable {
    public let id: String
    let name: String
    let udid: String

    init(device: SimulatorDevice) {
      self.id = device.id
      self.name = device.name
      self.udid = device.udid
    }
  }
}

// MARK: - MainWindowFeature.PairDevicesFormState
extension MainWindowFeature {
  public struct PairDevicesFormState: Equatable {
    var phoneDeviceID: String
    var watchDeviceID: String
  }
}

// MARK: - MainWindowFeature.UnpairDeviceConfirmationState
extension MainWindowFeature {
  public struct UnpairDeviceConfirmationState: Equatable {
    let pairID: String
    let phoneName: String
    let phoneUDID: String
    let watchName: String
    let watchUDID: String
  }
}

// MARK: - MainWindowFeature.AppDestructiveConfirmationState
extension MainWindowFeature {
  public struct AppDestructiveConfirmationState: Equatable {
    let appID: String
    let appName: String
    let bundleID: String
    let deviceID: String
    let deviceName: String
    let deviceUDID: String
    let dataContainerPath: String?
  }
}

// MARK: - MainWindowFeature.InstallAppTargetCandidate
extension MainWindowFeature {
  public struct InstallAppTargetCandidate: Equatable, Identifiable {
    public let id: String
    let name: String
    let udid: String
    let state: SimulatorDevice.State

    init(device: SimulatorDevice) {
      self.id = device.id
      self.name = device.name
      self.udid = device.udid
      self.state = device.state
    }
  }
}

// MARK: - MainWindowFeature.InstallAppTargetFormState
extension MainWindowFeature {
  public struct InstallAppTargetFormState: Equatable {
    let sourceAppID: String
    let sourceDeviceID: String
    let appName: String
    let bundleID: String
    let appBundlePath: URL
    var targetDeviceID: String
    var launchAfterInstall: Bool
  }
}

// MARK: - MainWindowFeature.AppCommandContext
extension MainWindowFeature {
  struct AppCommandContext {
    let device: SimulatorDevice
    let app: InstalledApp
  }
}
