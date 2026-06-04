import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MainWindowSheetsFeature
import MainWindowWorkflows
import MenuBarFeature
import SidebarFeature
import SimControlDomain
import WorkspaceFeature

@Reducer
public struct MainWindowFeature {
  static let menuBarAutoRefreshInterval: TimeInterval = 60

  @Dependency(\.developerToolWorkflow) var developerToolWorkflow
  @Dependency(\.deviceLifecycleWorkflow) var deviceLifecycleWorkflow
  @Dependency(\.installedAppWorkflow) var installedAppWorkflow
  @Dependency(\.inventoryWorkflow) var inventoryWorkflow
  @Dependency(\.pathActionWorkflow) var pathActionWorkflow

  public init() {}

  public enum Action: Equatable {
    case task
    case menuBar(MenuBarFeature.Action)
    case refreshButtonTapped
    case refreshResponse(SimulatorRefreshResult)
    case createSimulatorButtonTapped
    case cloneSelectedSimulatorButtonTapped
    case pairDevicesButtonTapped
    case lifecycleSheetDismissed
    case createDeviceSubmitted(CreateDeviceFormState)
    case cloneDeviceSubmitted(CloneDeviceFormState)
    case renameDeviceSubmitted(RenameDeviceFormState)
    case eraseDeviceConfirmed(DeviceDestructiveConfirmationState)
    case deleteDeviceConfirmed(DeviceDestructiveConfirmationState)
    case pairDevicesSubmitted(PairDevicesFormState)
    case unpairDeviceConfirmed(UnpairDeviceConfirmationState)
    case uninstallAppConfirmed(AppDestructiveConfirmationState)
    case resetAppSandboxConfirmed(AppDestructiveConfirmationState)
    case installAppOnSimulatorSubmitted(InstallAppTargetFormState)
    case openSimulatorAppButtonTapped
    case openSimulatorAppResponse(CommandResult)
    case pathActionResults([CommandResult])
    case deviceCommandResponse(DeviceCommandState, CommandResult)
    case deviceCommandRefreshResponse(
      DeviceCommandState,
      SimulatorRefreshResult,
      preferredSelectedDeviceID: String?
    )
    case appCommandCommandsCompleted(
      AppCommandState,
      [CommandResult],
      preferredSelectedDeviceID: String?,
      preferredSelectedAppID: String?
    )
    case appCommandRefreshResponse(
      AppCommandState,
      SimulatorRefreshResult,
      preferredSelectedDeviceID: String?,
      preferredSelectedAppID: String?
    )
    case developerToolCommandResults(
      DeviceCommandState,
      [CommandResult],
      refreshAfterward: Bool
    )
    case developerToolCommandRefreshResponse(
      DeviceCommandState,
      SimulatorRefreshResult,
      preferredSelectedDeviceID: String?
    )
    case sidebar(SidebarFeature.Action)
    case workspace(WorkspaceFeature.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      route(into: &state, action: action)
    }

    Scope(state: \.sidebar, action: \.sidebar) {
      SidebarFeature()
    }
    Scope(state: \.workspace, action: \.workspace) {
      WorkspaceFeature()
    }
    Scope(state: \.menuBar, action: \.menuBar) {
      MenuBarFeature()
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

// MARK: - MainWindowFeature Action Routing

extension MainWindowFeature {
  func route(
    into state: inout State,
    action: Action
  ) -> Effect<Action> {
    switch action {
    case .task,
         .menuBar,
         .refreshButtonTapped,
         .refreshResponse,
         .openSimulatorAppButtonTapped,
         .openSimulatorAppResponse:
      return routeMenuRefreshAction(into: &state, action: action)

    case .createSimulatorButtonTapped,
         .cloneSelectedSimulatorButtonTapped,
         .pairDevicesButtonTapped,
         .lifecycleSheetDismissed,
         .createDeviceSubmitted,
         .cloneDeviceSubmitted,
         .renameDeviceSubmitted,
         .eraseDeviceConfirmed,
         .deleteDeviceConfirmed,
         .pairDevicesSubmitted,
         .unpairDeviceConfirmed,
         .uninstallAppConfirmed,
         .resetAppSandboxConfirmed,
         .installAppOnSimulatorSubmitted:
      return routeSheetAction(into: &state, action: action)

    case .pathActionResults,
         .developerToolCommandResults,
         .developerToolCommandRefreshResponse,
         .deviceCommandResponse,
         .deviceCommandRefreshResponse,
         .appCommandCommandsCompleted,
         .appCommandRefreshResponse:
      return routeCommandResponseAction(into: &state, action: action)

    case .workspace(let workspaceAction):
      return routeWorkspaceAction(workspaceAction, into: &state)

    case .sidebar:
      return .none
    }
  }
}

// MARK: - MainWindowFeature Shared Input Helpers

extension MainWindowFeature {
  func nonEmpty(_ value: String) -> String? {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }
}
