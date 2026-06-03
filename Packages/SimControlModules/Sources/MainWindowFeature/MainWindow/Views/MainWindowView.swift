import ComposableArchitecture
import DeviceListFeature
import InspectorFeature
import SidebarFeature
import SimControlLocalization
import SimControlDomain
import MainWindowSheetsFeature
import SwiftUI
import WorkspaceFeature

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
      ToolbarItem {
        ControlGroup {
          Button {
            store.send(.createSimulatorButtonTapped)
          } label: {
            Label {
              Text(.localizable("main_window.toolbar.create_simulator"), bundle: .module)
            } icon: {
              Image(systemName: "plus")
            }
          }
          .disabled(!store.canCreateDevice)
          .help(String.localizable("main_window.toolbar.create_simulator.help", bundle: .module))

          Button {
            store.send(.cloneSelectedSimulatorButtonTapped)
          } label: {
            Label {
              Text(.localizable("main_window.toolbar.clone_simulator"), bundle: .module)
            } icon: {
              Image(systemName: "plus.square.on.square")
            }
          }
          .disabled(!store.canCloneSelectedDevice)
          .help(String.localizable("main_window.toolbar.clone_simulator.help", bundle: .module))

          Button {
            store.send(.pairDevicesButtonTapped)
          } label: {
            Label {
              Text(.localizable("main_window.toolbar.pair_simulators"), bundle: .module)
            } icon: {
              Image(systemName: "link")
            }
          }
          .disabled(!store.canPairDevices)
          .help(String.localizable("main_window.toolbar.pair_simulators.help", bundle: .module))

          Button {
            store.send(.refreshButtonTapped)
          } label: {
            if isRefreshing {
              ProgressView()
                .controlSize(.small)
                .frame(width: 18, height: 18)
            } else {
              Label {
                Text(.localizable("main_window.toolbar.refresh"), bundle: .module)
              } icon: {
                Image(systemName: "arrow.clockwise")
              }
            }
          }
          .disabled(isRefreshing)
          .help(String.localizable("main_window.toolbar.refresh.help", bundle: .module))
          .keyboardShortcut("r", modifiers: .command)
        }
      }

      ToolbarItemGroup(placement: .primaryAction) {
        Button {
          isInspectorPresented.toggle()
        } label: {
          Label {
            Text(.localizable("main_window.toolbar.inspector"), bundle: .module)
          } icon: {
            Image(systemName: "sidebar.trailing")
          }
        }
        .help(
          String.localizable(
            isInspectorPresented ? "main_window.toolbar.hide_inspector.help" : "main_window.toolbar.show_inspector.help",
            bundle: .module
          )
        )
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
          titleKey: "main_window.erase.title",
          messageKey: "main_window.erase.message",
          actionTitleKey: "main_window.erase.action",
          systemImage: "eraser",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.eraseDeviceConfirmed(confirmationState))
        }
      case .delete(let confirmationState):
        DeviceDestructiveConfirmationView(
          titleKey: "main_window.delete.title",
          messageKey: "main_window.delete.message",
          actionTitleKey: "main_window.delete.action",
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
          titleKey: "main_window.uninstall_app.title",
          messageKey: "main_window.uninstall_app.message",
          actionTitleKey: "main_window.uninstall_app.action",
          systemImage: "trash",
          confirmationState: confirmationState
        ) { confirmationState in
          store.send(.uninstallAppConfirmed(confirmationState))
        }
      case .resetAppSandbox(let confirmationState):
        AppDestructiveConfirmationView(
          titleKey: "main_window.reset_sandbox.title",
          messageKey: "main_window.reset_sandbox.message",
          actionTitleKey: "main_window.reset_sandbox.action",
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
