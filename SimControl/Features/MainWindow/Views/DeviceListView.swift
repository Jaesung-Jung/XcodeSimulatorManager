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

  private var availabilityFilter: Binding<SimulatorFilters.DeviceAvailabilityFilter> {
    Binding(
      get: { store.filters.deviceAvailabilityFilter },
      set: { store.send(.deviceAvailabilityFilterChanged($0)) }
    )
  }

  private var appPresenceFilter: Binding<SimulatorFilters.DeviceAppPresenceFilter> {
    Binding(
      get: { store.filters.deviceAppPresenceFilter },
      set: { store.send(.deviceAppPresenceFilterChanged($0)) }
    )
  }

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
        VStack(alignment: .leading, spacing: 2) {
          Text("Devices")
            .font(.headline)

          Text("\(store.devices.count) of \(store.totalDeviceCount) shown")
            .font(.caption)
            .foregroundStyle(.secondary)
        }

        Spacer()

        DeviceFilterMenu(
          availabilityFilter: availabilityFilter,
          appPresenceFilter: appPresenceFilter
        )

        DeviceSortMenu(
          sort: deviceSort,
          direction: deviceSortDirection
        )
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 12)

      if store.filters.hasActiveDeviceFilters {
        ActiveDeviceFilters(
          filters: store.filters,
          onClear: {
            store.send(.clearDeviceFiltersButtonTapped)
          }
        )
        .padding(.horizontal, 14)
        .padding(.bottom, 10)
      }

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
          message: "No simulator devices match the current search and filters.",
          systemImage: "line.3.horizontal.decrease.circle"
        )
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else {
        List(selection: selectedDeviceID) {
          ForEach(store.devices) { device in
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
  private struct DeviceFilterMenu: View {
    @Binding var availabilityFilter: SimulatorFilters.DeviceAvailabilityFilter
    @Binding var appPresenceFilter: SimulatorFilters.DeviceAppPresenceFilter

    var body: some View {
      Menu {
        Picker("Availability", selection: $availabilityFilter) {
          Text(SimulatorFilters.DeviceAvailabilityFilter.all.displayTitle)
            .tag(SimulatorFilters.DeviceAvailabilityFilter.all)
          Text(SimulatorFilters.DeviceAvailabilityFilter.available.displayTitle)
            .tag(SimulatorFilters.DeviceAvailabilityFilter.available)
          Text(SimulatorFilters.DeviceAvailabilityFilter.unavailable.displayTitle)
            .tag(SimulatorFilters.DeviceAvailabilityFilter.unavailable)
        }

        Picker("Apps", selection: $appPresenceFilter) {
          Text(SimulatorFilters.DeviceAppPresenceFilter.all.displayTitle)
            .tag(SimulatorFilters.DeviceAppPresenceFilter.all)
          Text(SimulatorFilters.DeviceAppPresenceFilter.hasApps.displayTitle)
            .tag(SimulatorFilters.DeviceAppPresenceFilter.hasApps)
          Text(SimulatorFilters.DeviceAppPresenceFilter.noApps.displayTitle)
            .tag(SimulatorFilters.DeviceAppPresenceFilter.noApps)
        }
      } label: {
        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
      }
      .help("Filter devices")
    }
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
  private struct ActiveDeviceFilters: View {
    let filters: SimulatorFilters
    let onClear: () -> Void

    var body: some View {
      HStack(spacing: 6) {
        if filters.sidebarScope != .all {
          FilterChip(title: filters.sidebarScope.displayTitle)
        }

        if filters.deviceAvailabilityFilter != .all {
          FilterChip(title: filters.deviceAvailabilityFilter.displayTitle)
        }

        if filters.deviceAppPresenceFilter != .all {
          FilterChip(title: filters.deviceAppPresenceFilter.displayTitle)
        }

        Spacer(minLength: 4)

        Button("Clear") {
          onClear()
        }
        .buttonStyle(.plain)
        .font(.caption)
      }
    }
  }
}

extension DeviceListView {
  private struct FilterChip: View {
    let title: String

    var body: some View {
      Text(title)
        .font(.caption)
        .padding(.horizontal, 7)
        .padding(.vertical, 3)
        .background(.quaternary.opacity(0.45), in: Capsule())
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
