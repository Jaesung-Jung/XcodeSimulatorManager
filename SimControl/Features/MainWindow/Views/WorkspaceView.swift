import ComposableArchitecture
import SwiftUI

@MainActor
struct WorkspaceView: View {
  let store: StoreOf<WorkspaceFeature>

  var body: some View {
    HStack(spacing: 0) {
      DetailContent(store: store)
        .frame(maxWidth: .infinity, maxHeight: .infinity)

      Divider()

      InspectorView(
        store: store.scope(state: \.inspector, action: \.inspector)
      )
      .frame(width: 320)
    }
    .background(.windowBackground)
  }
}

extension WorkspaceView {
  private struct DetailContent: View {
    let store: StoreOf<WorkspaceFeature>

    var body: some View {
      if store.snapshot == nil {
        InitialStateContent(refreshState: store.refreshState)
      } else if store.deviceList.devices.isEmpty {
        EmptyStateView(
          title: "No Simulators",
          message: "Refresh completed, but no simulator devices were returned.",
          systemImage: "iphone.slash"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.deviceDetail.device != nil {
        DeviceDetailView(
          store: store.scope(state: \.deviceDetail, action: \.deviceDetail)
        )
      } else {
        EmptyStateView(
          title: "Select a Simulator",
          message: "Choose a device from the list to inspect its runtime, folders, apps, and recent command results.",
          systemImage: "sidebar.left"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

extension WorkspaceView {
  private struct InitialStateContent: View {
    let refreshState: InventoryRefreshState

    var body: some View {
      switch refreshState {
      case .refreshing:
        RefreshProgressView(
          title: "Refreshing Inventory",
          message: "Loading simulator devices from the active Xcode selection."
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .failed(let diagnostic):
        EmptyStateView(
          title: "Refresh Failed",
          message: LocalizedStringKey(diagnostic),
          systemImage: "exclamationmark.triangle"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      case .idle:
        EmptyStateView(
          title: "Simulator Inventory",
          message: "Refresh simulator inventory to load devices from the active Xcode selection.",
          systemImage: "iphone"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
  }
}

extension WorkspaceView {
  private struct RefreshProgressView: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey

    var body: some View {
      HStack(spacing: 10) {
        ProgressView()
          .controlSize(.small)

        VStack(alignment: .leading, spacing: 2) {
          Text(title)
            .font(.subheadline.weight(.medium))

          Text(message)
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }
      .padding(12)
      .frame(maxWidth: .infinity, alignment: .leading)
    }
  }
}

// MARK: - WorkspaceView Preview

#if DEBUG

#Preview {
  WorkspaceView(
    store: Store(initialState: MainWindowFeature.State.preview.workspace) {
      WorkspaceFeature()
    }
  )
  .frame(width: 1_120, height: 720)
}

#endif
