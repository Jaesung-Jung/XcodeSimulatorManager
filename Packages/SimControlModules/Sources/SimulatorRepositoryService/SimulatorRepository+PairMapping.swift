import CoreSimulatorService
import SimControlDomain

extension SimulatorRepository {
  func mapPairs(
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

      return mapPair(
        id: id,
        sourcePair: sourcePair,
        deviceByID: deviceByID,
        warnings: &warnings
      )
    }
  }

  func mapPair(
    id: String,
    sourcePair: SimctlPair,
    deviceByID: [String: SimulatorDevice],
    warnings: inout [SimulatorWarning]
  ) -> DevicePair? {
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

  func pairHasBrokenReference(
    id: String,
    phoneDeviceID: String,
    watchDeviceID: String,
    deviceByID: [String: SimulatorDevice],
    warnings: inout [SimulatorWarning]
  ) -> Bool {
    var hasBrokenReference = false
    hasBrokenReference = checkPairDeviceReference(
      pairID: id,
      role: "phone",
      deviceID: phoneDeviceID,
      deviceByID: deviceByID,
      warnings: &warnings
    ) || hasBrokenReference
    hasBrokenReference = checkPairDeviceReference(
      pairID: id,
      role: "watch",
      deviceID: watchDeviceID,
      deviceByID: deviceByID,
      warnings: &warnings
    ) || hasBrokenReference
    return hasBrokenReference
  }

  func checkPairDeviceReference(
    pairID: String,
    role: String,
    deviceID: String,
    deviceByID: [String: SimulatorDevice],
    warnings: inout [SimulatorWarning]
  ) -> Bool {
    guard let device = deviceByID[deviceID] else {
      warnings.append(
        warning(
          id: "pair-\(pairID)-missing-\(role)-device",
          severity: .warning,
          category: .pair,
          message: "Pair \(pairID) references missing \(role) device \(deviceID).",
          relatedID: pairID
        )
      )
      return true
    }

    guard device.isAvailable else {
      warnings.append(
        warning(
          id: "pair-\(pairID)-\(role)-unavailable",
          severity: .warning,
          category: .pair,
          message: "Pair \(pairID) references unavailable \(role) device \(deviceID).",
          relatedID: pairID
        )
      )
      return true
    }

    return false
  }
}
