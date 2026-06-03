import CoreSimulatorService
import Foundation
import SimControlDomain

/// Builds domain snapshots from CoreSimulator service output.
public actor SimulatorRepository {
  typealias SelectedXcodePathProvider = () async -> CoreSimulatorService.DeveloperPathResult
  typealias SimctlListProvider = () async -> CoreSimulatorService.ListResult
  typealias InstalledAppsProvider = (SimulatorDevice) async -> AppContainerScanner.ScanResult

  private let selectedXcodePath: SelectedXcodePathProvider
  private let list: SimctlListProvider
  private let installedApps: InstalledAppsProvider
  private let now: () -> Date
  private var refreshTask: Task<SimulatorRefreshResult, Never>?

  /// Creates a simulator repository backed by concrete infrastructure services.
  public init(
    coreSimulatorService: CoreSimulatorService = CoreSimulatorService(),
    appContainerScanner: AppContainerScanner = AppContainerScanner(),
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
      installedApps: { device in
        appContainerScanner.scanInstalledApps(for: device)
      }
    )
  }

  init(
    now: @escaping () -> Date = Date.init,
    selectedXcodePath: @escaping SelectedXcodePathProvider,
    list: @escaping SimctlListProvider,
    installedApps: @escaping InstalledAppsProvider = { _ in
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

  private func performRefresh() async -> SimulatorRefreshResult {
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

  private func makeSnapshot(
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

  private func scanInstalledApps(
    for devices: [SimulatorDevice],
    warnings: inout [SimulatorWarning]
  ) async -> [String: [InstalledApp]] {
    var installedAppsByDeviceID: [String: [InstalledApp]] = [:]

    for device in devices {
      let scanResult = await installedApps(device)
      warnings.append(contentsOf: scanResult.warnings)

      if !scanResult.apps.isEmpty {
        installedAppsByDeviceID[device.id] = scanResult.apps
      }
    }

    return installedAppsByDeviceID
  }

  private func mapRuntimes(
    _ sourceRuntimes: [SimctlRuntime],
    warnings: inout [SimulatorWarning]
  ) -> [SimulatorRuntime] {
    sourceRuntimes.enumerated().compactMap { index, sourceRuntime in
      guard let id = nonEmpty(sourceRuntime.identifier) else {
        warnings.append(
          warning(
            id: "runtime-\(index)-missing-identifier",
            severity: .warning,
            category: .runtime,
            message: "A runtime entry is missing an identifier and was skipped.",
            relatedID: nil
          )
        )
        return nil
      }

      let platform = simulatorPlatform(from: sourceRuntime.platform)
      if platform == .unknown {
        warnings.append(
          warning(
            id: "runtime-\(id)-unknown-platform",
            severity: .warning,
            category: .runtime,
            message: "Runtime \(displayName(sourceRuntime.name, fallback: id)) has an unknown platform.",
            relatedID: id
          )
        )
      }

      let isAvailable = sourceRuntime.isAvailable ?? true
      if !isAvailable {
        warnings.append(
          warning(
            id: "runtime-\(id)-unavailable",
            severity: .warning,
            category: .runtime,
            message: "Runtime \(displayName(sourceRuntime.name, fallback: id)) is unavailable.",
            relatedID: id
          )
        )
      }

      var supportedDeviceTypeIDs: [String] = []
      for (supportedIndex, supportedDeviceType) in sourceRuntime.supportedDeviceTypes.enumerated() {
        guard let supportedDeviceTypeID = nonEmpty(supportedDeviceType.identifier) else {
          warnings.append(
            warning(
              id: "runtime-\(id)-supported-device-type-\(supportedIndex)-missing-identifier",
              severity: .warning,
              category: .runtime,
              message: "Runtime \(displayName(sourceRuntime.name, fallback: id)) lists a supported device type without an identifier.",
              relatedID: id
            )
          )
          continue
        }

        supportedDeviceTypeIDs.append(supportedDeviceTypeID)
      }

      return SimulatorRuntime(
        id: id,
        name: displayName(sourceRuntime.name, fallback: id),
        version: nonEmpty(sourceRuntime.version) ?? "",
        buildVersion: nonEmpty(sourceRuntime.buildVersion) ?? "",
        platform: platform,
        isAvailable: isAvailable,
        supportedDeviceTypeIDs: supportedDeviceTypeIDs
      )
    }
  }

  private func mapDeviceTypes(
    _ sourceDeviceTypes: [SimctlDeviceType],
    warnings: inout [SimulatorWarning]
  ) -> [SimulatorDeviceType] {
    sourceDeviceTypes.enumerated().compactMap { index, sourceDeviceType in
      guard let id = nonEmpty(sourceDeviceType.identifier) else {
        warnings.append(
          warning(
            id: "device-type-\(index)-missing-identifier",
            severity: .warning,
            category: .device,
            message: "A device type entry is missing an identifier and was skipped.",
            relatedID: nil
          )
        )
        return nil
      }

      return SimulatorDeviceType(
        id: id,
        name: displayName(sourceDeviceType.name, fallback: id),
        productFamily: nonEmpty(sourceDeviceType.productFamily),
        modelIdentifier: nonEmpty(sourceDeviceType.modelIdentifier)
      )
    }
  }

  private func mapDevices(
    _ devicesByRuntimeID: [String: [SimctlDevice]],
    runtimeByID: [String: SimulatorRuntime],
    warnings: inout [SimulatorWarning]
  ) -> [SimulatorDevice] {
    var devices: [SimulatorDevice] = []

    for runtimeID in devicesByRuntimeID.keys.sorted() {
      guard !runtimeID.isEmpty else {
        warnings.append(
          warning(
            id: "device-group-missing-runtime-identifier",
            severity: .warning,
            category: .device,
            message: "A device group is missing a runtime identifier and was skipped.",
            relatedID: nil
          )
        )
        continue
      }

      let runtime = runtimeByID[runtimeID]
      if runtime == nil {
        warnings.append(
          warning(
            id: "runtime-\(runtimeID)-missing-for-devices",
            severity: .warning,
            category: .runtime,
            message: "Devices reference runtime \(runtimeID), but that runtime was not listed.",
            relatedID: runtimeID
          )
        )
      }

      for (deviceIndex, sourceDevice) in (devicesByRuntimeID[runtimeID] ?? []).enumerated() {
        guard let udid = nonEmpty(sourceDevice.udid) else {
          warnings.append(
            warning(
              id: "device-\(runtimeID)-\(deviceIndex)-missing-identifier",
              severity: .warning,
              category: .device,
              message: "A device entry is missing a UDID and was skipped.",
              relatedID: runtimeID
            )
          )
          continue
        }

        let state = deviceState(from: sourceDevice.state)
        if state == .unknown {
          warnings.append(
            warning(
              id: "device-\(udid)-unknown-state",
              severity: .warning,
              category: .device,
              message: "Device \(displayName(sourceDevice.name, fallback: udid)) has an unknown state.",
              relatedID: udid
            )
          )
        }

        let isAvailable = sourceDevice.isAvailable ?? true
        if !isAvailable {
          warnings.append(
            warning(
              id: "device-\(udid)-unavailable",
              severity: .warning,
              category: .device,
              message: "Device \(displayName(sourceDevice.name, fallback: udid)) is unavailable.",
              relatedID: udid
            )
          )
        }

        let deviceTypeID = nonEmpty(sourceDevice.deviceTypeIdentifier) ?? ""
        if deviceTypeID.isEmpty {
          warnings.append(
            warning(
              id: "device-\(udid)-missing-device-type-identifier",
              severity: .warning,
              category: .device,
              message: "Device \(displayName(sourceDevice.name, fallback: udid)) is missing a device type identifier.",
              relatedID: udid
            )
          )
        }

        devices.append(
          SimulatorDevice(
            id: udid,
            udid: udid,
            name: displayName(sourceDevice.name, fallback: udid),
            runtimeID: runtimeID,
            deviceTypeID: deviceTypeID,
            platform: runtime?.platform ?? .unknown,
            state: state,
            isAvailable: isAvailable,
            dataPath: fileURL(from: sourceDevice.dataPath),
            logPath: fileURL(from: sourceDevice.logPath),
            lastBootedAt: date(from: sourceDevice.lastBootedAt),
            dataPathSize: sourceDevice.dataPathSize
          )
        )
      }
    }

    return devices
  }

  private func mapPairs(
    _ pairsByID: [String: SimctlPair],
    deviceByID: [String: SimulatorDevice],
    warnings: inout [SimulatorWarning]
  ) -> [DevicePair] {
    pairsByID.keys.sorted().compactMap { id in
      guard !id.isEmpty else {
        warnings.append(
          warning(
            id: "pair-missing-identifier",
            severity: .warning,
            category: .pair,
            message: "A pair entry is missing an identifier and was skipped.",
            relatedID: nil
          )
        )
        return nil
      }

      guard let sourcePair = pairsByID[id] else {
        return nil
      }

      guard let phoneDeviceID = nonEmpty(sourcePair.phone?.udid) else {
        warnings.append(
          warning(
            id: "pair-\(id)-missing-phone-identifier",
            severity: .warning,
            category: .pair,
            message: "Pair \(id) is missing a phone device identifier and was skipped.",
            relatedID: id
          )
        )
        return nil
      }

      guard let watchDeviceID = nonEmpty(sourcePair.watch?.udid) else {
        warnings.append(
          warning(
            id: "pair-\(id)-missing-watch-identifier",
            severity: .warning,
            category: .pair,
            message: "Pair \(id) is missing a watch device identifier and was skipped.",
            relatedID: id
          )
        )
        return nil
      }

      let sourceState = pairState(from: sourcePair.state)
      if sourceState == .unknown {
        warnings.append(
          warning(
            id: "pair-\(id)-unknown-state",
            severity: .warning,
            category: .pair,
            message: "Pair \(id) has an unknown state.",
            relatedID: id
          )
        )
      }

      let hasBrokenReference = pairHasBrokenReference(
        id: id,
        phoneDeviceID: phoneDeviceID,
        watchDeviceID: watchDeviceID,
        deviceByID: deviceByID,
        warnings: &warnings
      )

      return DevicePair(
        id: id,
        phoneDeviceID: phoneDeviceID,
        watchDeviceID: watchDeviceID,
        state: hasBrokenReference ? .unavailable : sourceState
      )
    }
  }

  private func pairHasBrokenReference(
    id: String,
    phoneDeviceID: String,
    watchDeviceID: String,
    deviceByID: [String: SimulatorDevice],
    warnings: inout [SimulatorWarning]
  ) -> Bool {
    var hasBrokenReference = false

    if let phoneDevice = deviceByID[phoneDeviceID] {
      if !phoneDevice.isAvailable {
        hasBrokenReference = true
        warnings.append(
          warning(
            id: "pair-\(id)-phone-unavailable",
            severity: .warning,
            category: .pair,
            message: "Pair \(id) references unavailable phone device \(phoneDeviceID).",
            relatedID: id
          )
        )
      }
    } else {
      hasBrokenReference = true
      warnings.append(
        warning(
          id: "pair-\(id)-missing-phone-device",
          severity: .warning,
          category: .pair,
          message: "Pair \(id) references missing phone device \(phoneDeviceID).",
          relatedID: id
        )
      )
    }

    if let watchDevice = deviceByID[watchDeviceID] {
      if !watchDevice.isAvailable {
        hasBrokenReference = true
        warnings.append(
          warning(
            id: "pair-\(id)-watch-unavailable",
            severity: .warning,
            category: .pair,
            message: "Pair \(id) references unavailable watch device \(watchDeviceID).",
            relatedID: id
          )
        )
      }
    } else {
      hasBrokenReference = true
      warnings.append(
        warning(
          id: "pair-\(id)-missing-watch-device",
          severity: .warning,
          category: .pair,
          message: "Pair \(id) references missing watch device \(watchDeviceID).",
          relatedID: id
        )
      )
    }

    return hasBrokenReference
  }

  private func simulatorPlatform(from rawPlatform: String?) -> SimulatorPlatform {
    switch normalized(rawPlatform) {
    case "ios", "iphonesimulator", "comappleplatformiphonesimulator":
      return .iOS
    case "watchos", "watchsimulator", "comappleplatformwatchsimulator":
      return .watchOS
    case "tvos", "appletvsimulator", "comappleplatformappletvsimulator":
      return .tvOS
    case "visionos", "xros", "xrsimulator", "comappleplatformxrsimulator":
      return .visionOS
    default:
      return .unknown
    }
  }

  private func deviceState(from rawState: String?) -> SimulatorDevice.State {
    switch normalized(rawState) {
    case "creating":
      return .creating
    case "shutdown":
      return .shutdown
    case "booting":
      return .booting
    case "booted":
      return .booted
    case "shuttingdown":
      return .shuttingDown
    default:
      return .unknown
    }
  }

  private func pairState(from rawState: String?) -> DevicePair.State {
    switch normalized(rawState) {
    case "active":
      return .active
    case "inactive":
      return .inactive
    case "unavailable":
      return .unavailable
    default:
      return .unknown
    }
  }

  private func keyedByID<Value: Identifiable>(_ values: [Value]) -> [String: Value] where Value.ID == String {
    var result: [String: Value] = [:]
    for value in values where result[value.id] == nil {
      result[value.id] = value
    }
    return result
  }

  private func warning(
    id: String,
    severity: SimulatorWarning.Severity,
    category: SimulatorWarning.Category,
    message: String,
    relatedID: String?
  ) -> SimulatorWarning {
    SimulatorWarning(
      id: id,
      severity: severity,
      category: category,
      message: message,
      relatedID: relatedID
    )
  }

  private func displayName(_ value: String?, fallback: String) -> String {
    nonEmpty(value) ?? fallback
  }

  private func nonEmpty(_ value: String?) -> String? {
    guard let trimmedValue = value?.trimmingCharacters(in: .whitespacesAndNewlines),
          !trimmedValue.isEmpty
    else {
      return nil
    }

    return trimmedValue
  }

  private func normalized(_ value: String?) -> String {
    nonEmpty(value)?
      .lowercased()
      .filter(\.isLetter) ?? ""
  }

  private func fileURL(from path: String?) -> URL? {
    guard let path = nonEmpty(path) else {
      return nil
    }

    return URL(fileURLWithPath: path)
  }

  private func date(from value: String?) -> Date? {
    guard let value = nonEmpty(value) else {
      return nil
    }

    let formatter = ISO8601DateFormatter()
    if let date = formatter.date(from: value) {
      return date
    }

    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter.date(from: value)
  }
}
