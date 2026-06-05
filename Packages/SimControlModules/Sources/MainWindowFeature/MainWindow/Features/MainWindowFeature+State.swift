import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MenuBarFeature
import SidebarFeature
import SimControlDomain
import WorkspaceFeature

// MARK: - MainWindowFeature.State
extension MainWindowFeature {
  /// Root state for the main window feature tree.
  @ObservableState
  public struct State: Equatable {
    var lastMenuBarAutoRefreshAttemptAt: Date?
    var lifecycleSheet: DeviceLifecycleSheet?
    var sidebar: SidebarFeature.State
    public var workspace: WorkspaceFeature.State

    init(
      snapshot: SimulatorSnapshot? = nil,
      refreshState: InventoryRefreshState = .idle,
      selectedDeviceID: String? = nil,
      selectedAppID: String? = nil,
      installedAppsAvailability: InstalledAppsAvailability? = nil,
      deviceCommandState: DeviceCommandState? = nil,
      appCommandState: AppCommandState? = nil,
      isOpeningSimulatorApp: Bool = false,
      filters: SimulatorFilters = SimulatorFilters(),
      lastMenuBarAutoRefreshAttemptAt: Date? = nil,
      lifecycleSheet: DeviceLifecycleSheet? = nil
    ) {
      self.lastMenuBarAutoRefreshAttemptAt = lastMenuBarAutoRefreshAttemptAt
      self.lifecycleSheet = lifecycleSheet
      self.sidebar = SidebarFeature.State(
        snapshot: snapshot,
        refreshState: refreshState
      )
      self.workspace = WorkspaceFeature.State(
        snapshot: snapshot,
        refreshState: refreshState,
        selectedDeviceID: selectedDeviceID,
        selectedAppID: selectedAppID,
        installedAppsAvailability: installedAppsAvailability,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp,
        filters: filters
      )
    }

    public static var initial: Self { Self() }

    public var menuBar: MenuBarFeature.State {
      get { MenuBarFeature.State(workspace: workspace) }
      set {}
    }
  }
}

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
