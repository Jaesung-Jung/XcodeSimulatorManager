import AppKit
import ComposableArchitecture
import SwiftUI

@MainActor
struct MenuBarAppActionsView: View {
  let store: StoreOf<MainWindowFeature>
  let openMainWindow: () -> Void

  private var isRefreshing: Bool {
    store.workspace.refreshState == .refreshing
  }

  private var refreshTitle: String {
    isRefreshing ? "Refreshing" : "Refresh"
  }

  var body: some View {
    Section {
      Button {
        openMainWindow()
      } label: {
        Label("Open SimControl", systemImage: "macwindow")
      }

      Button {
        store.send(.refreshButtonTapped)
      } label: {
        Label(refreshTitle, systemImage: "arrow.clockwise")
      }
      .disabled(isRefreshing)

      Button {
        store.send(.openSimulatorAppButtonTapped)
      } label: {
        Label("Open Simulator.app", systemImage: "play.rectangle")
      }
    }

    Section {
      SettingsLink {
        Label("Settings", systemImage: "gearshape")
      }

      Button {
        NSApplication.shared.terminate(nil)
      } label: {
        Label("Quit SimControl", systemImage: "power")
      }
    }
  }
}

// MARK: - MenuBarAppActionsView Preview

#if DEBUG

#Preview {
  MenuBarAppActionsView(
    store: .mainWindowPreview,
    openMainWindow: {}
  )
}

#endif
