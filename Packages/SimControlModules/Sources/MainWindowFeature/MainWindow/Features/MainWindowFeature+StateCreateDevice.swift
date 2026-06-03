import SimControlDomain

// MARK: - MainWindowFeature.State Create Device

extension MainWindowFeature.State {
  static func initialCreateDeviceFormState(
    in snapshot: SimulatorSnapshot
  ) -> MainWindowFeature.CreateDeviceFormState? {
    for runtime in snapshot.runtimes where runtime.isAvailable {
      guard let deviceType = compatibleDeviceTypes(
        for: runtime,
        in: snapshot.deviceTypes
      ).first else {
        continue
      }

      return MainWindowFeature.CreateDeviceFormState(
        runtimeID: runtime.id,
        deviceTypeID: deviceType.id
      )
    }

    return nil
  }

  private static func compatibleDeviceTypes(
    for runtime: SimulatorRuntime,
    in deviceTypes: [SimulatorDeviceType]
  ) -> [SimulatorDeviceType] {
    guard !runtime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }
}
