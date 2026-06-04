import ComposableArchitecture
import SimControlSharedUI
import SwiftUI

// MARK: - InspectorView.Content

extension InspectorView {
  struct Content: View {
    let store: StoreOf<InspectorFeature>

    var body: some View {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          if let device = store.device {
            DeviceSection(store: store, device: device)

            Divider()

            DeviceFoldersSection(store: store, device: device)
          } else {
            EmptyStateView(
              title: "No Selection",
              message: "Select a simulator to inspect identifiers, folders, and environment.",
              systemImage: "info.circle"
            )
            .frame(maxWidth: .infinity)
          }

          if let selectedApp = store.selectedApp {
            Divider()

            SelectedAppSection(store: store, selectedApp: selectedApp)

            if !selectedApp.appGroups.isEmpty {
              Divider()

              AppGroupsSection(store: store, selectedApp: selectedApp)
            }
          }

          Divider()

          EnvironmentSection(snapshot: store.snapshot)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .topLeading)
      }
      .background(.background)
    }
  }
}

// MARK: - InspectorView.Content Preview

#if DEBUG

#Preview {
  InspectorView.Content(
    store: Store(initialState: InspectorFeature.State()) {
      InspectorFeature()
    }
  )
  .frame(width: 320, height: 640)
}

#endif
