import CoreSimulatorService
import Foundation
import SimControlDomain

extension SimulatorRepository {
  func performRefresh() async -> SimulatorRefreshResult {
    let xcodePathResult = await selectedXcodePath()

    guard xcodePathResult.succeeded else {
      return SimulatorRefreshResult(
        snapshot: nil,
        xcodeCommandResult: xcodePathResult.commandResult,
        listCommandResult: nil,
        diagnostic: xcodePathResult.diagnostic ?? "Unable to determine the active Xcode developer path."
      )
    }

    let listResult = await list()

    guard listResult.succeeded, let payload = listResult.payload else {
      return SimulatorRefreshResult(
        snapshot: nil,
        xcodeCommandResult: xcodePathResult.commandResult,
        listCommandResult: listResult.commandResult,
        diagnostic: listResult.diagnostic ?? "Unable to load simulator inventory."
      )
    }

    let snapshot = await makeSnapshot(
      from: payload,
      developerPath: xcodePathResult.developerPath,
      xcodeIsValid: xcodePathResult.succeeded
    )

    return SimulatorRefreshResult(
      snapshot: snapshot,
      xcodeCommandResult: xcodePathResult.commandResult,
      listCommandResult: listResult.commandResult,
      diagnostic: nil
    )
  }

  func makeSnapshot(
    from payload: SimctlListPayload,
    developerPath: URL?,
    xcodeIsValid: Bool
  ) async -> SimulatorSnapshot {
    var warnings: [SimulatorWarning] = []
    let runtimes = mapRuntimes(payload.runtimes, warnings: &warnings)
    let runtimeByID = keyedByID(runtimes)
    let deviceTypes = mapDeviceTypes(payload.deviceTypes, warnings: &warnings)
    let devices = mapDevices(
      payload.devicesByRuntimeID,
      runtimeByID: runtimeByID,
      warnings: &warnings
    )
    let deviceByID = keyedByID(devices)
    let pairs = mapPairs(
      payload.pairsByID,
      deviceByID: deviceByID,
      warnings: &warnings
    )
    let installedAppsByDeviceID = await scanInstalledApps(
      for: devices,
      runtimeByID: runtimeByID,
      warnings: &warnings
    )

    return SimulatorSnapshot(
      generatedAt: now(),
      xcode: XcodeSelection(
        developerPath: developerPath,
        version: nil,
        isValid: xcodeIsValid
      ),
      runtimes: runtimes,
      deviceTypes: deviceTypes,
      devices: devices,
      pairs: pairs,
      installedAppsByDeviceID: installedAppsByDeviceID,
      warnings: warnings
    )
  }

  func scanInstalledApps(
    for devices: [SimulatorDevice],
    runtimeByID: [String: SimulatorRuntime],
    warnings: inout [SimulatorWarning]
  ) async -> [String: [InstalledApp]] {
    var installedAppsByDeviceID: [String: [InstalledApp]] = [:]

    for device in devices {
      let scanResult = await installedApps(device, runtimeByID[device.runtimeID]?.runtimeRoot)
      let listAppsResult = await listApps(device.id)
      warnings.append(contentsOf: scanResult.warnings)
      let apps = mergedApps(
        scanResult.apps,
        listApps: listAppsResult.appsByBundleID,
        deviceID: device.id
      )

      if !apps.isEmpty {
        installedAppsByDeviceID[device.id] = apps
      }
    }

    return installedAppsByDeviceID
  }

  func mergedApps(
    _ apps: [InstalledApp],
    listApps: [String: CoreSimulatorService.ListedApp],
    deviceID: String
  ) -> [InstalledApp] {
    apps.map { app in
      guard let listedApp = listApps[app.bundleID] else {
        return app
      }

      let knownGroupIDs = Set(app.appGroups.map(\.groupID))
      let listedAppGroups = listedApp.groupContainers
        .filter { !knownGroupIDs.contains($0.key) }
        .map { groupID, path in
          AppGroupContainer(
            id: "\(deviceID):\(groupID)",
            groupID: groupID,
            path: path
          )
        }
        .sorted { $0.groupID.localizedStandardCompare($1.groupID) == .orderedAscending }

      return InstalledApp(
        id: app.id,
        bundleID: app.bundleID,
        displayName: app.displayName,
        version: app.version,
        build: app.build,
        deviceID: app.deviceID,
        bundleContainer: app.bundleContainer,
        dataContainer: app.dataContainer ?? listedApp.dataContainer,
        appBundlePath: app.appBundlePath ?? listedApp.appBundlePath,
        appGroups: app.appGroups + listedAppGroups,
        iconPath: app.iconPath,
        isSystemApp: app.isSystemApp,
        isHiddenSystemApp: app.isHiddenSystemApp,
        databaseFiles: app.databaseFiles,
        dataContainerSize: app.dataContainerSize
      )
    }
  }
}
