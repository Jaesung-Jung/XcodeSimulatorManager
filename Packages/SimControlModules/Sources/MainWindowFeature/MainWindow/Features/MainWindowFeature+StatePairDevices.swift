import SimControlDomain

// MARK: - MainWindowFeature.State Pair Devices

extension MainWindowFeature.State {
  static func initialPairDevicesFormState(
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

  static func pairPhoneCandidates(
    in snapshot: SimulatorSnapshot
  ) -> [MainWindowFeature.PairDeviceCandidate] {
    snapshot.devices
      .filter { isPairPhoneCandidate($0, in: snapshot) }
      .map { MainWindowFeature.PairDeviceCandidate(device: $0) }
  }

  static func pairWatchCandidates(
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
