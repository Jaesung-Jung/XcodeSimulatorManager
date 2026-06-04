import CoreSimulatorService
import SimControlDomain

extension SimulatorRepository {
  func mapRuntimes(
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
        runtimeRoot: fileURL(from: sourceRuntime.runtimeRoot),
        supportedDeviceTypeIDs: supportedDeviceTypeIDs
      )
    }
  }
}
