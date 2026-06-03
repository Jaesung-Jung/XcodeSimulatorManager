import Foundation
import MainWindowSheetsFeature
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

// MARK: - MainWindowFeature Sheet Typealiases
extension MainWindowFeature {
  public typealias DeviceLifecycleSheet = MainWindowSheetsFeature.DeviceLifecycleSheet
  public typealias DeviceDestructiveConfirmationState = MainWindowSheetsFeature.DeviceDestructiveConfirmationState
  public typealias CreateDeviceFormState = MainWindowSheetsFeature.CreateDeviceFormState
  public typealias CloneDeviceFormState = MainWindowSheetsFeature.CloneDeviceFormState
  public typealias RenameDeviceFormState = MainWindowSheetsFeature.RenameDeviceFormState
  public typealias PairDeviceCandidate = MainWindowSheetsFeature.PairDeviceCandidate
  public typealias PairDevicesFormState = MainWindowSheetsFeature.PairDevicesFormState
  public typealias UnpairDeviceConfirmationState = MainWindowSheetsFeature.UnpairDeviceConfirmationState
  public typealias AppDestructiveConfirmationState = MainWindowSheetsFeature.AppDestructiveConfirmationState
  public typealias InstallAppTargetCandidate = MainWindowSheetsFeature.InstallAppTargetCandidate
  public typealias InstallAppTargetFormState = MainWindowSheetsFeature.InstallAppTargetFormState
}

// MARK: - MainWindowFeature.AppCommandContext
extension MainWindowFeature {
  struct AppCommandContext {
    let device: SimulatorDevice
    let app: InstalledApp
  }
}

// MARK: - MainWindowFeature Input Helpers
extension MainWindowFeature {
  func nonEmpty(_ value: String) -> String? {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }
}
