import ComposableArchitecture
import MainWindowDisplaySupport
import SimControlDomain
import SwiftUI

extension DeviceListView {
  struct Header: View {
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
    }
  }

  struct DeviceSortMenu: View {
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
