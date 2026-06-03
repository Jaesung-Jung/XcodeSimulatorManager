import Foundation

extension SimulatorInventoryQuery {
  func sortedApps(_ apps: [InstalledApp]) -> [InstalledApp] {
    apps.sorted { first, second in
      let firstPinned = filters.pinnedAppIDs.contains(first.id)
      let secondPinned = filters.pinnedAppIDs.contains(second.id)
      if firstPinned != secondPinned {
        return firstPinned
      }

      let comparison = appComparison(first, second)
      if comparison == .orderedSame {
        return first.id.localizedStandardCompare(second.id) == .orderedAscending
      }

      return ordered(comparison, direction: filters.appSortDirection)
    }
  }

  func appComparison(
    _ first: InstalledApp,
    _ second: InstalledApp
  ) -> ComparisonResult {
    switch filters.appSort {
    case .name:
      return first.displayName.localizedStandardCompare(second.displayName)
    case .bundleID:
      return first.bundleID.localizedStandardCompare(second.bundleID)
    case .version:
      return (first.version ?? "").localizedStandardCompare(second.version ?? "")
    case .dataSize:
      return compare(first.dataContainerSize ?? -1, second.dataContainerSize ?? -1)
    }
  }
}
