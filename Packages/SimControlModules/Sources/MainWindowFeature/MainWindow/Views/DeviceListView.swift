import ComposableArchitecture
import MainWindowDisplaySupport
import SimControlSharedUI
import SimControlDomain
import SwiftUI

struct DeviceListView: View {
  let store: StoreOf<DeviceListFeature>

  private var deviceSort: Binding<SimulatorFilters.DeviceSort> {
    Binding(
      get: { store.filters.deviceSort },
      set: { store.send(.deviceSortChanged($0)) }
    )
  }

  private var deviceSortDirection: Binding<SimulatorFilters.SortDirection> {
    Binding(
      get: { store.filters.deviceSortDirection },
      set: { store.send(.deviceSortDirectionChanged($0)) }
    )
  }

  var body: some View {
    VStack(spacing: 0) {
      HStack(spacing: 8) {
        Text("Devices")
          .font(.headline)

        Spacer()

        DeviceSortMenu(
          sort: deviceSort,
          direction: deviceSortDirection
        )
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)

      Divider()

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
          LazyVStack(alignment: .leading, spacing: 0) {
            ForEach(store.devices) { device in
              Button {
                store.send(.selectionChanged(device.id))
              } label: {
                Row(
                  device: device,
                  runtime: store.runtimeByID[device.runtimeID],
                  deviceType: store.deviceTypeByID[device.deviceTypeID],
                  installedAppCount: installedAppCount(for: device),
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

  private func installedAppCount(for device: SimulatorDevice) -> Int? {
    guard store.installedAppsAvailability == .loaded else {
      return nil
    }

    return store.installedAppsByDeviceID[device.id]?.count ?? 0
  }
}

extension DeviceListView {
  private struct DeviceSortMenu: View {
    @Binding var sort: SimulatorFilters.DeviceSort
    @Binding var direction: SimulatorFilters.SortDirection

    var body: some View {
      Menu {
        Picker("Sort By", selection: $sort) {
          Text(SimulatorFilters.DeviceSort.name.displayTitle)
            .tag(SimulatorFilters.DeviceSort.name)
          Text(SimulatorFilters.DeviceSort.state.displayTitle)
            .tag(SimulatorFilters.DeviceSort.state)
          Text(SimulatorFilters.DeviceSort.runtime.displayTitle)
            .tag(SimulatorFilters.DeviceSort.runtime)
          Text(SimulatorFilters.DeviceSort.platform.displayTitle)
            .tag(SimulatorFilters.DeviceSort.platform)
          Text(SimulatorFilters.DeviceSort.lastBootedAt.displayTitle)
            .tag(SimulatorFilters.DeviceSort.lastBootedAt)
          Text(SimulatorFilters.DeviceSort.dataSize.displayTitle)
            .tag(SimulatorFilters.DeviceSort.dataSize)
        }

        Divider()

        Picker("Direction", selection: $direction) {
          Text(SimulatorFilters.SortDirection.ascending.displayTitle)
            .tag(SimulatorFilters.SortDirection.ascending)
          Text(SimulatorFilters.SortDirection.descending.displayTitle)
            .tag(SimulatorFilters.SortDirection.descending)
        }
      } label: {
        Label("Sort", systemImage: "arrow.up.arrow.down")
      }
      .help("Sort devices")
    }
  }
}

extension DeviceListView {
  private struct Row: View {
    let device: SimulatorDevice
    let runtime: SimulatorRuntime?
    let deviceType: SimulatorDeviceType?
    let installedAppCount: Int?
    let isPinned: Bool
    let onPin: () -> Void

    private var subtitle: String {
      let runtimeName = runtime?.name ?? device.runtimeID
      let typeName = deviceType?.name ?? device.deviceTypeID
      return "\(runtimeName) - \(typeName)"
    }

    var body: some View {
      HStack(spacing: 10) {
        Image(systemName: device.symbolName)
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

            if let installedAppCount, installedAppCount > 0 {
              StatusBadge(
                title: "\(installedAppCount) apps"
              )
            }
          }
        }

        Spacer(minLength: 8)

        VStack(alignment: .trailing, spacing: 6) {
          Button {
            onPin()
          } label: {
            Image(systemName: isPinned ? "pin.fill" : "pin")
              .foregroundStyle(isPinned ? Color.accentColor : Color.secondary)
          }
          .buttonStyle(.plain)
          .help(isPinned ? "Unpin device" : "Pin device")

          if device.dataPathSize != nil {
            Text(device.dataPathSizeTitle)
              .font(.caption2)
              .foregroundStyle(.secondary)
              .lineLimit(1)
          }
        }
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
