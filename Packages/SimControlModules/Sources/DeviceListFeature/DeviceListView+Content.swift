import ComposableArchitecture
import SimControlDomain
import SimControlSharedUI
import SwiftUI

extension DeviceListView {
  struct Content: View {
    let store: StoreOf<DeviceListFeature>

    var body: some View {
      if store.totalDeviceCount == 0 {
        EmptyStateView(
          title: "No Devices",
          message: "Simulator inventory has no devices to show.",
          systemImage: "iphone.slash"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if store.devices.isEmpty {
        EmptyStateView(
          title: "No Matching Devices",
          message: "No simulator devices match the current search or sidebar selection.",
          systemImage: "line.3.horizontal.decrease.circle"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 4) {
            ForEach(store.devices) { device in
              Button {
                store.send(.selectionChanged(device.id))
              } label: {
                Row(
                  device: device,
                  runtime: store.runtimeByID[device.runtimeID],
                  deviceType: store.deviceTypeByID[device.deviceTypeID],
                  isPinned: store.filters.pinnedDeviceIDs.contains(device.id),
                  onPin: {
                    store.send(.pinButtonTapped(device.id))
                  }
                )
                .tag(device.id)
                .padding(.horizontal, 16)
                .padding(.vertical, 4)
                .contentShape(.rect)
                .background {
                  RoundedRectangle(cornerRadius: 8)
                    .fill(.quaternary)
                    .padding(.horizontal, 8)
                    .opacity(store.selectedDeviceID == device.id ? 1 : 0)
                }
              }
              .buttonStyle(.plain)
            }
          }
          .padding(.vertical, 8)
          .animation(.spring, value: store.devices)
        }
        .scrollIndicators(.hidden)
      }
    }
  }
}

// MARK: - DeviceListView.Content Preview

#if DEBUG

#Preview {
  DeviceListView.Content(
    store: Store(initialState: DeviceListFeature.State()) {
      DeviceListFeature()
    }
  )
  .frame(width: 360, height: 480)
}

#endif
