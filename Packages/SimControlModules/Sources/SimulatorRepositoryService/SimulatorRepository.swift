import AppContainerScanningService
import CoreSimulatorService
import Foundation
import SimControlDomain

/// Builds domain snapshots from CoreSimulator service output.
public actor SimulatorRepository {
  typealias SelectedXcodePathProvider = () async -> CoreSimulatorService.DeveloperPathResult
  typealias SimctlListProvider = () async -> CoreSimulatorService.ListResult
  typealias InstalledAppsProvider = (SimulatorDevice, URL?) async -> AppContainerScanner.ScanResult

  let selectedXcodePath: SelectedXcodePathProvider
  let list: SimctlListProvider
  let installedApps: InstalledAppsProvider
  let now: () -> Date
  var refreshTask: Task<SimulatorRefreshResult, Never>?

  /// Creates a simulator repository backed by concrete infrastructure services.
  public init(
    coreSimulatorService: CoreSimulatorService = CoreSimulatorService(),
    now: @escaping () -> Date = Date.init
  ) {
    self.init(
      now: now,
      selectedXcodePath: {
        await coreSimulatorService.selectedXcodePath()
      },
      list: {
        await coreSimulatorService.list()
      },
      installedApps: { device, runtimeRoot in
        AppContainerScanner().scanInstalledApps(for: device, runtimeRoot: runtimeRoot)
      }
    )
  }

  /// Creates a simulator repository backed by concrete infrastructure services.
  public init(
    coreSimulatorService: CoreSimulatorService = CoreSimulatorService(),
    appContainerScanner: AppContainerScanner,
    now: @escaping () -> Date = Date.init
  ) {
    self.init(
      now: now,
      selectedXcodePath: {
        await coreSimulatorService.selectedXcodePath()
      },
      list: {
        await coreSimulatorService.list()
      },
      installedApps: { device, runtimeRoot in
        appContainerScanner.scanInstalledApps(for: device, runtimeRoot: runtimeRoot)
      }
    )
  }

  init(
    now: @escaping () -> Date = Date.init,
    selectedXcodePath: @escaping SelectedXcodePathProvider,
    list: @escaping SimctlListProvider,
    installedApps: @escaping InstalledAppsProvider = { _, _ in
      AppContainerScanner.ScanResult(apps: [], warnings: [])
    }
  ) {
    self.selectedXcodePath = selectedXcodePath
    self.list = list
    self.installedApps = installedApps
    self.now = now
  }

  /// Refreshes simulator inventory and maps service-layer values into domain values.
  public func refresh() async -> SimulatorRefreshResult {
    if let refreshTask {
      return await refreshTask.value
    }

    let refreshTask = Task {
      await performRefresh()
    }
    self.refreshTask = refreshTask

    let result = await refreshTask.value
    self.refreshTask = nil

    return result
  }
}
