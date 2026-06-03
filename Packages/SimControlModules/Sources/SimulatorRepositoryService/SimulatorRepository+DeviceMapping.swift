import CoreSimulatorService
import SimControlDomain

extension SimulatorRepository {
  func mapDeviceTypes(
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

  func mapDevices(
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

      appendDevices(
        devicesByRuntimeID[runtimeID] ?? [],
        runtimeID: runtimeID,
        runtime: runtime,
        warnings: &warnings,
        devices: &devices
      )
    }

    return devices
  }

  func appendDevices(
    _ sourceDevices: [SimctlDevice],
    runtimeID: String,
    runtime: SimulatorRuntime?,
    warnings: inout [SimulatorWarning],
    devices: inout [SimulatorDevice]
  ) {
    for (deviceIndex, sourceDevice) in sourceDevices.enumerated() {
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

      appendDevice(
        sourceDevice,
        udid: udid,
        runtimeID: runtimeID,
        runtime: runtime,
        warnings: &warnings,
        devices: &devices
      )
    }
  }

  func appendDevice(
    _ sourceDevice: SimctlDevice,
    udid: String,
    runtimeID: String,
    runtime: SimulatorRuntime?,
    warnings: inout [SimulatorWarning],
    devices: inout [SimulatorDevice]
  ) {
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
