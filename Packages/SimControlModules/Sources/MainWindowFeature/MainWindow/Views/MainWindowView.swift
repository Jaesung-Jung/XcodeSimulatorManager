import ComposableArchitecture
import SimControlDomain
import SwiftUI

@MainActor
public struct MainWindowView: View {
  @State private var isInspectorPresented = true

  let store: StoreOf<MainWindowFeature>

  public init(store: StoreOf<MainWindowFeature>) {
    self.store = store
  }

  private var isRefreshing: Bool {
    store.workspace.refreshState == .refreshing
  }

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
      Sidebar(
        store: store.scope(state: \.sidebar, action: \.sidebar),
        filters: store.workspace.filters,
        onScopeSelected: { scope in
          store.send(.workspace(.sidebarScopeChanged(scope)))
        }
      )
      .navigationSplitViewColumnWidth(min: 220, ideal: 240, max: 300)
    } content: {
      DeviceListView(
        store: store.scope(
          state: \.workspace.deviceList,
          action: \.workspace.deviceList
        )
      )
      .navigationSplitViewColumnWidth(min: 300, ideal: 360, max: 420)
    } detail: {
      WorkspaceView(
        store: store.scope(state: \.workspace, action: \.workspace)
      )
    }
    .inspector(isPresented: $isInspectorPresented) {
      InspectorView(
        store: store.scope(
          state: \.workspace.inspector,
          action: \.workspace.inspector
        )
      )
      .background(.windowBackground)
    }
    .frame(minWidth: 1_120, minHeight: 720)
    .background(.windowBackground)
    .toolbar {
//      ToolbarItemGroup(placement: .status) {
//        TextField("Search", text: searchQuery)
//          .textFieldStyle(.roundedBorder)
//          .frame(width: 260)
//          .help("Search devices, apps, identifiers, and known paths")
//      }

      ToolbarItem {
        ControlGroup {
          Button {
            store.send(.createSimulatorButtonTapped)
          } label: {
            Label("Create Simulator", systemImage: "plus")
          }
          .disabled(!store.canCreateDevice)
          .help("Create simulator")

          Button {
            store.send(.cloneSelectedSimulatorButtonTapped)
          } label: {
            Label("Clone Simulator", systemImage: "plus.square.on.square")
          }
          .disabled(!store.canCloneSelectedDevice)
          .help("Clone selected simulator")

          Button {
            store.send(.pairDevicesButtonTapped)
          } label: {
            Label("Pair Simulators", systemImage: "link")
          }
          .disabled(!store.canPairDevices)
          .help("Pair watch and phone simulators")

          Button {
            store.send(.refreshButtonTapped)
          } label: {
            if isRefreshing {
              ProgressView()
                .controlSize(.small)
                .frame(width: 18, height: 18)
            } else {
              Label("Refresh", systemImage: "arrow.clockwise")
            }
          }
          .disabled(isRefreshing)
          .help("Refresh simulator inventory")
          .keyboardShortcut("r", modifiers: .command)
        }
      }

      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          isInspectorPresented.toggle()
        } label: {
          Label("Inspector", systemImage: "sidebar.trailing")
        }
        .help(isInspectorPresented ? "Hide inspector" : "Show inspector")
      }
    }
    .sheet(item: lifecycleSheet) { sheet in
      switch sheet {
      case .create(let formState):
        if let snapshot = store.workspace.snapshot {
          CreateDeviceView(
            formState: formState,
            runtimes: snapshot.runtimes,
            deviceTypes: snapshot.deviceTypes
          ) { formState in
            store.send(.createDeviceSubmitted(formState))
          }
        }
      case .clone(let formState):
        CloneDeviceView(formState: formState) { formState in
          store.send(.cloneDeviceSubmitted(formState))
        }
      case .rename(let formState):
        RenameDeviceView(formState: formState) { formState in
          store.send(.renameDeviceSubmitted(formState))
        }
      case .erase(let confirmationState):
        DeviceDestructiveConfirmationView(
          title: "Erase Simulator",
          message: "Erase this simulator's contents and settings.",
          actionTitle: "Erase",
          systemImage: "eraser",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.eraseDeviceConfirmed(confirmationState))
        }
      case .delete(let confirmationState):
        DeviceDestructiveConfirmationView(
          title: "Delete Simulator",
          message: "Delete this simulator.",
          actionTitle: "Delete",
          systemImage: "trash",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.deleteDeviceConfirmed(confirmationState))
        }
      case .pair(let formState):
        PairDevicesView(
          formState: formState,
          phoneCandidates: store.pairPhoneCandidates,
          watchCandidates: store.pairWatchCandidates
        ) { formState in
          store.send(.pairDevicesSubmitted(formState))
        }
      case .unpair(let confirmationState):
        UnpairDeviceConfirmationView(confirmationState: confirmationState) { confirmationState in
          store.send(.unpairDeviceConfirmed(confirmationState))
        }
      case .uninstallApp(let confirmationState):
        AppDestructiveConfirmationView(
          title: "Uninstall App",
          message: "Uninstall this app from the selected simulator.",
          actionTitle: "Uninstall",
          systemImage: "trash",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.uninstallAppConfirmed(confirmationState))
        }
      case .resetAppSandbox(let confirmationState):
        AppDestructiveConfirmationView(
          title: "Reset Sandbox",
          message: "Delete this app's sandbox contents while keeping the app installed.",
          actionTitle: "Reset",
          systemImage: "folder.badge.minus",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.resetAppSandboxConfirmed(confirmationState))
        }
      case .installAppOnSimulator(let formState):
        InstallAppOnSimulatorView(
          formState: formState,
          targetCandidates: store.presentedInstallAppTargetCandidates
        ) { formState in
          store.send(.installAppOnSimulatorSubmitted(formState))
        }
      }
    }
    .task {
      await store.send(.task).finish()
    }
  }
}

// MARK: - MainWindowView Preview

#if DEBUG

#Preview {
  MainWindowView(store: .mainWindowPreview)
}

#endif
