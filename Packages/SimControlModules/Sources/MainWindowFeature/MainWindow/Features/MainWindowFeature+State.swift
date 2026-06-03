import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MenuBarFeature
import SidebarFeature
import SimControlDomain
import WorkspaceFeature

// MARK: - MainWindowFeature.State
extension MainWindowFeature {
  @ObservableState
  public struct State: Equatable {
    var lastMenuBarAutoRefreshAttemptAt: Date?
    var lifecycleSheet: DeviceLifecycleSheet?
    var sidebar: SidebarFeature.State
    public var workspace: WorkspaceFeature.State

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      selectedDeviceID: String? = nil,
      selectedAppID: String? = nil,
      lastCommandResults: [CommandResult] = [],
      installedAppsAvailability: InstalledAppsAvailability? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      isOpeningSimulatorApp: Bool = false,
      filters: SimulatorFilters = SimulatorFilters(),
      lastMenuBarAutoRefreshAttemptAt: Date? = nil,
      lifecycleSheet: DeviceLifecycleSheet? = nil
    ) {
      self.lastMenuBarAutoRefreshAttemptAt = lastMenuBarAutoRefreshAttemptAt
      self.lifecycleSheet = lifecycleSheet
      self.sidebar = SidebarFeature.State(
        snapshot: snapshot,
        refreshState: refreshState
      )
      self.workspace = WorkspaceFeature.State(
        snapshot: snapshot,
        refreshState: refreshState,
        selectedDeviceID: selectedDeviceID,
        selectedAppID: selectedAppID,
        commandResults: lastCommandResults,
        installedAppsAvailability: installedAppsAvailability,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp,
        filters: filters
      )
    }

    public static var initial: Self {
      Self()
    }

    public var menuBar: MenuBarFeature.State {
      get { MenuBarFeature.State(workspace: workspace) }
      set {}
    }
  }
}
