import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature.State Device Lifecycle

extension MainWindowFeature.State {
  var canCreateDevice: Bool {
    workspace.deviceCommandState == nil
      && workspace.appCommandState == nil
      && initialCreateDeviceFormState != nil
  }

  var canCloneSelectedDevice: Bool {
    workspace.deviceCommandState == nil
      && workspace.appCommandState == nil
      && workspace.selectedDevice != nil
  }

  var canPairDevices: Bool {
    workspace.deviceCommandState == nil
      && workspace.appCommandState == nil
      && initialPairDevicesFormState != nil
  }

  var initialCreateDeviceFormState: MainWindowFeature.CreateDeviceFormState? {
    guard let snapshot = workspace.snapshot else {
      return nil
    }

    return Self.initialCreateDeviceFormState(in: snapshot)
  }

  var initialPairDevicesFormState: MainWindowFeature.PairDevicesFormState? {
    guard let snapshot = workspace.snapshot else {
      return nil
    }

    return Self.initialPairDevicesFormState(
      in: snapshot,
      selectedDeviceID: workspace.deviceList.selectedDeviceID
    )
  }

  var pairPhoneCandidates: [MainWindowFeature.PairDeviceCandidate] {
    guard let snapshot = workspace.snapshot else {
      return []
    }

    return Self.pairPhoneCandidates(in: snapshot)
  }

  var pairWatchCandidates: [MainWindowFeature.PairDeviceCandidate] {
    guard let snapshot = workspace.snapshot else {
      return []
    }

    return Self.pairWatchCandidates(in: snapshot)
  }

  private static func initialCreateDeviceFormState(
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

  private static func initialPairDevicesFormState(
    in snapshot: SimulatorSnapshot,
    selectedDeviceID: String?
  ) -> MainWindowFeature.PairDevicesFormState? {
    let phoneCandidates = pairPhoneCandidates(in: snapshot)
    let watchCandidates = pairWatchCandidates(in: snapshot)

    guard !phoneCandidates.isEmpty, !watchCandidates.isEmpty else {
      return nil
    }

    let selectedPhoneID = phoneCandidates.first { $0.id == selectedDeviceID }?.id
    let selectedWatchID = watchCandidates.first { $0.id == selectedDeviceID }?.id

    return MainWindowFeature.PairDevicesFormState(
      phoneDeviceID: selectedPhoneID ?? phoneCandidates[0].id,
      watchDeviceID: selectedWatchID ?? watchCandidates[0].id
    )
  }

  private static func pairPhoneCandidates(
    in snapshot: SimulatorSnapshot
  ) -> [MainWindowFeature.PairDeviceCandidate] {
    snapshot.devices
      .filter { isPairPhoneCandidate($0, in: snapshot) }
      .map { MainWindowFeature.PairDeviceCandidate(device: $0) }
  }

  private static func pairWatchCandidates(
    in snapshot: SimulatorSnapshot
  ) -> [MainWindowFeature.PairDeviceCandidate] {
    let pairedWatchDeviceIDs = Set(snapshot.pairs.map(\.watchDeviceID))

    return snapshot.devices
      .filter {
        isPairWatchCandidate(
          $0,
          in: snapshot,
          pairedWatchDeviceIDs: pairedWatchDeviceIDs
        )
      }
      .map { MainWindowFeature.PairDeviceCandidate(device: $0) }
  }

  private static func isPairPhoneCandidate(
    _ device: SimulatorDevice,
    in snapshot: SimulatorSnapshot
  ) -> Bool {
    guard device.isAvailable,
          device.platform == .iOS,
          let deviceType = snapshot.deviceTypes.first(where: { $0.id == device.deviceTypeID })
    else {
      return false
    }

    return deviceType.productFamily == "iPhone"
  }

  private static func isPairWatchCandidate(
    _ device: SimulatorDevice,
    in snapshot: SimulatorSnapshot,
    pairedWatchDeviceIDs: Set<String>
  ) -> Bool {
    guard device.isAvailable,
          device.platform == .watchOS,
          !pairedWatchDeviceIDs.contains(device.id),
          let deviceType = snapshot.deviceTypes.first(where: { $0.id == device.deviceTypeID })
    else {
      return false
    }

    return deviceType.productFamily == "Apple Watch"
  }
}
