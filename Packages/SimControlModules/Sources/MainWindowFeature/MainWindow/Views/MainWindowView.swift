import ComposableArchitecture
import MainWindowWorkflows
import SimControlDomain
import SwiftUI

/// Renders the main simulator management window.
@MainActor
public struct MainWindowView: View {
  @State private var isInspectorPresented = true

  let store: StoreOf<MainWindowFeature>

  /// Creates a main window view bound to a main window store.
  public init(store: StoreOf<MainWindowFeature>) {
    self.store = store
  }

  private var isRefreshing: Bool { store.workspace.refreshState == .refreshing }

  private var lifecycleSheet: Binding<MainWindowFeature.DeviceLifecycleSheet?> {
    Binding(
      get: { store.lifecycleSheet },
      set: { sheet in
        if sheet == nil {
          store.send(.lifecycleSheetDismissed)
        }
      }
    )
  }

  private var searchQuery: Binding<String> {
    Binding(
      get: { store.workspace.filters.searchQuery },
      set: { store.send(.workspace(.searchQueryChanged($0))) }
    )
  }

  public var body: some View {
    NavigationSplitView {
      SidebarColumn(store: store)
    } content: {
      DeviceListColumn(store: store)
    } detail: {
      WorkspaceDetail(store: store)
    }
    .inspector(isPresented: $isInspectorPresented) {
      InspectorPane(store: store)
    }
    .frame(minWidth: 1_120, minHeight: 720)
    .background(.windowBackground)
    .toolbar {
      MainToolbar(
        store: store,
        isRefreshing: isRefreshing,
        isInspectorPresented: $isInspectorPresented
      )
    }
    .sheet(item: lifecycleSheet) { sheet in
      LifecycleSheetContent(store: store, sheet: sheet)
    }
    .task {
      await store.send(.task).finish()
    }
  }
}

// MARK: - MainWindowView Preview

#if DEBUG

#Preview {
  let commandResult = CommandResult(
    id: "preview-command",
    executable: "preview",
    arguments: [],
    stdout: "",
    stderr: "",
    exitCode: 0,
    duration: 0,
    startedAt: Date(timeIntervalSince1970: 1_000)
  )

  let refreshResult = SimulatorRefreshResult(
    snapshot: nil,
    xcodeCommandResult: commandResult,
    listCommandResult: nil,
    diagnostic: "Preview inventory is intentionally empty."
  )

  let deviceLifecycleResult = DeviceLifecycleWorkflowResult(
    commandResult: commandResult,
    refreshResult: refreshResult,
    preferredSelectedDeviceID: nil
  )

  let installedAppResult = InstalledAppWorkflowResult(
    commandResults: [commandResult],
    refreshResult: refreshResult,
    preferredSelectedDeviceID: nil,
    preferredSelectedAppID: nil
  )

  let developerToolResult = DeveloperToolWorkflowResult(
    commandResults: [commandResult],
    refreshResult: refreshResult,
    preferredSelectedDeviceID: nil
  )

  let inventoryWorkflow = InventoryWorkflowClient(
    refresh: {
      refreshResult
    },
    openSimulatorApp: {
      commandResult
    }
  )

  let deviceLifecycleWorkflow = DeviceLifecycleWorkflowClient(
    bootDevice: { _ in deviceLifecycleResult },
    shutdownDevice: { _ in deviceLifecycleResult },
    createDevice: { _, _, _ in deviceLifecycleResult },
    cloneDevice: { _, _ in deviceLifecycleResult },
    renameDevice: { _, _ in deviceLifecycleResult },
    eraseDevice: { _ in deviceLifecycleResult },
    deleteDevice: { _ in deviceLifecycleResult },
    pairDevices: { _, _ in deviceLifecycleResult },
    unpairDevice: { _ in deviceLifecycleResult }
  )

  let installedAppWorkflow = InstalledAppWorkflowClient(
    launchApp: { _, _, _, _ in installedAppResult },
    terminateApp: { _, _, _ in installedAppResult },
    uninstallApp: { _, _, _ in installedAppResult },
    resetSandbox: { _, _, _ in installedAppResult },
    installAppOnSimulator: { _ in installedAppResult }
  )

  let developerToolWorkflow = DeveloperToolWorkflowClient(
    openURL: { _, _, _ in developerToolResult },
    sendRemoteNotification: { _, _, _, _ in developerToolResult },
    setPrivacyPermission: { _, _, _, _, _ in developerToolResult },
    setLocation: { _, _, _ in developerToolResult },
    clearLocation: { _, _ in developerToolResult },
    setStatusBarOverride: { _, _ in developerToolResult },
    clearStatusBarOverride: { _ in developerToolResult }
  )

  let pathActionWorkflow = PathActionWorkflowClient(
    runDevicePathAction: { _, _, _ in [commandResult] },
    copyValue: { _, _ in [commandResult] },
    runAppContainerPathAction: { _ in [commandResult] }
  )

  MainWindowView(
    store: Store(initialState: .initial) {
      MainWindowFeature()
    } withDependencies: {
      $0.inventoryWorkflow = inventoryWorkflow
      $0.deviceLifecycleWorkflow = deviceLifecycleWorkflow
      $0.installedAppWorkflow = installedAppWorkflow
      $0.developerToolWorkflow = developerToolWorkflow
      $0.pathActionWorkflow = pathActionWorkflow
    }
  )
}

#endif
