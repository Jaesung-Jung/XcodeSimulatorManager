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
}
