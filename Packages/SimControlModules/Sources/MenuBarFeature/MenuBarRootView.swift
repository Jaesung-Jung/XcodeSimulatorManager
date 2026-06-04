import AppKit
import ComposableArchitecture
import MainWindowFeatureSupport
import SimControlDomain
import SwiftUI

@MainActor
public struct MenuBarRootView: View {
  @Environment(\.openWindow) private var openWindow

  let store: StoreOf<MenuBarFeature>

  public init(store: StoreOf<MenuBarFeature>) {
    self.store = store
  }

  public var body: some View {
    Group {
      StatusSection(
        snapshot: store.snapshot,
        refreshState: store.refreshState
      )

      Divider()

      MenuBarAppActionsView(
        store: store,
        openMainWindow: openMainWindow
      )

      Divider()

      MenuBarDeviceSection(
        store: store,
        openMainWindow: openMainWindow
      )
    }
    .task {
      await store.send(.presented(at: Date())).finish()
    }
  }

  private func openMainWindow() {
    openWindow(id: MainWindowSceneID.mainWindow)
    NSApplication.shared.activate()
  }
}

extension MenuBarRootView {
  private struct StatusSection: View {
    let snapshot: SimulatorSnapshot?
    let refreshState: InventoryRefreshState

    private var title: String {
      switch refreshState {
      case .refreshing:
        "Refreshing Inventory"
      case .failed:
        "Refresh Failed"
      case .idle:
        if let snapshot {
          "\(snapshot.devices.count) Devices"
        } else {
          "Inventory Not Loaded"
        }
      }
    }

    private var detail: String? {
      switch refreshState {
      case .refreshing:
        "Loading simulator state in the background."
      case .failed(let diagnostic):
        diagnostic
      case .idle:
        if let snapshot {
          "Last updated \(snapshot.generatedAt.formatted(date: .omitted, time: .shortened))"
        } else {
          "Open the menu or refresh to load simulator inventory."
        }
      }
    }

    private var systemImage: String {
      switch refreshState {
      case .refreshing:
        "arrow.clockwise"
      case .failed:
        "exclamationmark.triangle"
      case .idle:
        snapshot == nil ? "iphone.slash" : "iphone"
      }
    }

    var body: some View {
      Section {
        Label(title, systemImage: systemImage)

        if let detail {
          Text(detail)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
  }
}

// MARK: - MenuBarRootView Preview

#if DEBUG

#Preview {
  MenuBarRootView(
    store: Store(initialState: MenuBarFeature.State()) {
      MenuBarFeature()
    }
  )
}

#endif
