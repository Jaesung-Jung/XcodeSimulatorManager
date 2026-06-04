import ComposableArchitecture
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
          Text(LocalizedStringResource.mainWindowToolbarCreateSimulator)
        } icon: {
          Image(systemName: "plus")
        }
      }
      .disabled(!store.canCreateDevice)
      .help(String(localized: LocalizedStringResource.mainWindowToolbarCreateSimulatorHelp))
    }

    private var cloneButton: some View {
      Button {
        store.send(.cloneSelectedSimulatorButtonTapped)
      } label: {
        Label {
          Text(LocalizedStringResource.mainWindowToolbarCloneSimulator)
        } icon: {
          Image(systemName: "plus.square.on.square")
        }
      }
      .disabled(!store.canCloneSelectedDevice)
      .help(String(localized: LocalizedStringResource.mainWindowToolbarCloneSimulatorHelp))
    }

    private var pairButton: some View {
      Button {
        store.send(.pairDevicesButtonTapped)
      } label: {
        Label {
          Text(LocalizedStringResource.mainWindowToolbarPairSimulators)
        } icon: {
          Image(systemName: "link")
        }
      }
      .disabled(!store.canPairDevices)
      .help(String(localized: LocalizedStringResource.mainWindowToolbarPairSimulatorsHelp))
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
            Text(LocalizedStringResource.mainWindowToolbarRefresh)
          } icon: {
            Image(systemName: "arrow.clockwise")
          }
        }
      }
      .disabled(isRefreshing)
      .help(String(localized: LocalizedStringResource.mainWindowToolbarRefreshHelp))
      .keyboardShortcut("r", modifiers: .command)
    }

    private var inspectorButton: some View {
      Button {
        isInspectorPresented.toggle()
      } label: {
        Label {
          Text(LocalizedStringResource.mainWindowToolbarInspector)
        } icon: {
          Image(systemName: "sidebar.trailing")
        }
      }
      .help(
        String(
          localized: isInspectorPresented
            ? LocalizedStringResource.mainWindowToolbarHideInspectorHelp
            : LocalizedStringResource.mainWindowToolbarShowInspectorHelp
        )
      )
    }
  }
}
