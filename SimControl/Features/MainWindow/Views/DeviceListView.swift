import ComposableArchitecture
import SwiftUI

struct DeviceListView: View {
  let store: StoreOf<DeviceListFeature>

  private var selectedDeviceID: Binding<String?> {
    Binding(
      get: { store.selectedDeviceID },
      set: { store.send(.selectionChanged($0)) }
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack {
        VStack(alignment: .leading, spacing: 2) {
          Text("Devices")
            .font(.headline)

          Text("\(store.devices.count) total")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)

      Divider()

      if store.devices.isEmpty {
        EmptyStateView(
          title: "No Devices",
          message: "Simulator inventory has no devices to show.",
          systemImage: "iphone.slash"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(selection: selectedDeviceID) {
          ForEach(store.devices) { device in
            Row(
              device: device,
              runtime: store.runtimeByID[device.runtimeID],
              deviceType: store.deviceTypeByID[device.deviceTypeID],
              installedAppCount: installedAppCount(for: device)
            )
            .tag(Optional(device.id))
          }
        }
        .listStyle(.inset)
      }
    }
    .background(.background)
  }

  private func installedAppCount(for device: SimulatorDevice) -> Int? {
    guard store.installedAppsAvailability == .loaded else {
      return nil
    }

    return store.installedAppsByDeviceID[device.id]?.count ?? 0
  }
}

extension DeviceListView {
  private struct Row: View {
    let device: SimulatorDevice
    let runtime: SimulatorRuntime?
    let deviceType: SimulatorDeviceType?
    let installedAppCount: Int?

    private var subtitle: String {
      let runtimeName = runtime?.name ?? device.runtimeID
      let typeName = deviceType?.name ?? device.deviceTypeID
      return "\(runtimeName) - \(typeName)"
    }

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: device.platform.symbolName)
          .font(.title3)
          .foregroundStyle(.secondary)
          .frame(width: 24)
          .accessibilityHidden(true)

        VStack(alignment: .leading, spacing: 4) {
          Text(device.name)
            .font(.subheadline.weight(.medium))
            .lineLimit(1)

          Text(subtitle)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)

          HStack(spacing: 6) {
            StatusBadge(
              title: LocalizedStringKey(device.state.displayTitle)
            )
            .tint(device.state.statusTint)

            if let installedAppCount {
              StatusBadge(
                title: "\(installedAppCount) apps",
                systemImage: "app"
              )
            } else {
              StatusBadge(
                title: "Apps pending",
                systemImage: "app"
              )
            }
          }
        }

        Spacer(minLength: 8)
      }
      .padding(.vertical, 5)
      .accessibilityElement(children: .combine)
      .accessibilityLabel("\(device.name), \(subtitle), \(device.state.displayTitle)")
    }
  }
}

// MARK: - DeviceListView Preview

#if DEBUG

#Preview {
  DeviceListView(
    store: Store(
      initialState: MainWindowFeature.State.preview.workspace.deviceList
    ) {
      DeviceListFeature()
    }
  )
  .frame(width: 360, height: 720)
}

#endif
