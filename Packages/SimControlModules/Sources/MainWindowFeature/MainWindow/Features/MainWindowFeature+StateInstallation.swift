import MainWindowFeatureSupport
import SimControlDomain

// MARK: - MainWindowFeature.State Installation

extension MainWindowFeature.State {
  var presentedInstallAppTargetCandidates: [MainWindowFeature.InstallAppTargetCandidate] {
    guard case .installAppOnSimulator(let formState) = lifecycleSheet else {
      return []
    }

    return installAppTargetCandidates(for: formState)
  }

  func installAppTargetCandidates(
    for formState: MainWindowFeature.InstallAppTargetFormState
  ) -> [MainWindowFeature.InstallAppTargetCandidate] {
    guard let snapshot = workspace.snapshot,
          let sourceDevice = snapshot.devices.first(where: { $0.id == formState.sourceDeviceID })
    else {
      return []
    }

    return Self.installAppTargetCandidates(
      in: snapshot,
      sourceDevice: sourceDevice
    )
  }

  private static func installAppTargetCandidates(
    in snapshot: SimulatorSnapshot,
    sourceDevice: SimulatorDevice
  ) -> [MainWindowFeature.InstallAppTargetCandidate] {
    snapshot.devices
      .filter { target in
        target.id != sourceDevice.id
          && target.isAvailable
          && target.platform == sourceDevice.platform
          && (target.state == .booted || target.state == .shutdown)
      }
      .map { MainWindowFeature.InstallAppTargetCandidate(device: $0) }
  }
}
