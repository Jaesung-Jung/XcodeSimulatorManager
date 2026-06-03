import ComposableArchitecture
import DeviceDetailFeature
import DeviceListFeature
import InspectorFeature
import SimControlDomain

@Reducer
public struct WorkspaceFeature {
  public init() {}

  public enum Action: Equatable {
    case searchQueryChanged(String)
    case sidebarScopeChanged(SimulatorFilters.SidebarScope)
    case deviceList(DeviceListFeature.Action)
    case deviceDetail(DeviceDetailFeature.Action)
    case inspector(InspectorFeature.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .searchQueryChanged(let query):
        state.setSearchQuery(query)
        return .none

      case .sidebarScopeChanged(let scope):
        state.setSidebarScope(scope)
        return .none

      case .deviceList(.selectionChanged(let id)):
        state.selectDevice(id: id)
        return .none

      case .deviceList(.pinButtonTapped(let id)):
        state.togglePinnedDevice(id: id)
        return .none

      case .deviceList(.deviceSortChanged(let sort)):
        state.setDeviceSort(sort)
        return .none

      case .deviceList(.deviceSortDirectionChanged(let direction)):
        state.setDeviceSortDirection(direction)
        return .none

      case .deviceDetail(.installedApps(.selectionChanged(let id))):
        state.selectApp(id: id)
        return .none

      case .deviceDetail(.installedApps(.pinButtonTapped(let id))):
        state.togglePinnedApp(id: id)
        return .none

      case .deviceDetail(.installedApps(.appSystemFilterChanged(let filter))):
        state.setAppSystemFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appGroupFilterChanged(let filter))):
        state.setAppGroupFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appDatabaseFilterChanged(let filter))):
        state.setAppDatabaseFilter(filter)
        return .none

      case .deviceDetail(.installedApps(.appSortChanged(let sort))):
        state.setAppSort(sort)
        return .none

      case .deviceDetail(.installedApps(.appSortDirectionChanged(let direction))):
        state.setAppSortDirection(direction)
        return .none

      case .deviceDetail(.installedApps(.clearAppFiltersButtonTapped)):
        state.clearAppFilters()
        return .none

      case .deviceDetail, .inspector:
        return .none
      }
    }

    Scope(state: \.deviceList, action: \.deviceList) {
      DeviceListFeature()
    }
    Scope(state: \.deviceDetail, action: \.deviceDetail) {
      DeviceDetailFeature()
    }
    Scope(state: \.inspector, action: \.inspector) {
      InspectorFeature()
    }
  }
}
