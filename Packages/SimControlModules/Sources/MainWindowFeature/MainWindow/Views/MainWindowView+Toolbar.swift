import ComposableArchitecture
import SimControlLocalization
import SwiftUI

// MARK: - MainWindowView.MainToolbar

@MainActor
extension MainWindowView {
  struct MainToolbar: ToolbarContent {
    let store: StoreOf<MainWindowFeature>
    let isRefreshing: Bool
    @Binding var isInspectorPresented: Bool

    var body: some ToolbarContent {
      ToolbarItem {
        ControlGroup {
          createButton
          cloneButton
          pairButton
          refreshButton
        }
      }

      ToolbarItemGroup(placement: .primaryAction) {
        inspectorButton
      }
    }

    private var createButton: some View {
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
    }

    private var cloneButton: some View {
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
    }

    private var pairButton: some View {
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
    }

    private var refreshButton: some View {
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

    private var inspectorButton: some View {
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
}
