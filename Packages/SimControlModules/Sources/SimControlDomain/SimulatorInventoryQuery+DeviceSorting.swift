import Foundation

extension SimulatorInventoryQuery {
  func sortedDevices(_ devices: [SimulatorDevice]) -> [SimulatorDevice] {
    devices.sorted { first, second in
      let comparison = deviceComparison(first, second)
      if comparison == .orderedSame {
        return first.id.localizedStandardCompare(second.id) == .orderedAscending
      }

      return ordered(comparison, direction: filters.deviceSortDirection)
    }
  }

  func deviceComparison(
    _ first: SimulatorDevice,
    _ second: SimulatorDevice
  ) -> ComparisonResult {
    switch filters.deviceSort {
    case .name:
      return first.name.localizedStandardCompare(second.name)
    case .state:
      return first.state.inventoryTitle.localizedStandardCompare(second.state.inventoryTitle)
    case .runtime:
      return (runtimeByID[first.runtimeID]?.name ?? first.runtimeID)
        .localizedStandardCompare(runtimeByID[second.runtimeID]?.name ?? second.runtimeID)
    case .platform:
      return first.platform.inventoryTitle.localizedStandardCompare(second.platform.inventoryTitle)
    case .lastBootedAt:
      return compare(
        first.lastBootedAt?.timeIntervalSince1970 ?? -1,
        second.lastBootedAt?.timeIntervalSince1970 ?? -1
      )
    case .dataSize:
      return compare(first.dataPathSize ?? -1, second.dataPathSize ?? -1)
    }
  }
}
