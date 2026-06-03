import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MenuBarFeature
import SidebarFeature
import SimControlDomain
import WorkspaceFeature

// MARK: - MainWindowFeature.State
extension MainWindowFeature {
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
      lastCommandResults: [CommandResult] = [],
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
        commandResults: lastCommandResults,
        installedAppsAvailability: installedAppsAvailability,
        deviceCommandState: deviceCommandState,
        appCommandState: appCommandState,
        isOpeningSimulatorApp: isOpeningSimulatorApp,
        filters: filters
      )
    }

    public static var initial: Self {
      Self()
    }

    public var menuBar: MenuBarFeature.State {
      get { MenuBarFeature.State(workspace: workspace) }
      set {}
    }

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

    var initialCreateDeviceFormState: CreateDeviceFormState? {
      guard let snapshot else {
        return nil
      }

      return Self.initialCreateDeviceFormState(in: snapshot)
    }

    var initialPairDevicesFormState: PairDevicesFormState? {
      guard let snapshot else {
        return nil
      }

      return Self.initialPairDevicesFormState(
        in: snapshot,
        selectedDeviceID: workspace.deviceList.selectedDeviceID
      )
    }

    var pairPhoneCandidates: [PairDeviceCandidate] {
      guard let snapshot else {
        return []
      }

      return Self.pairPhoneCandidates(in: snapshot)
    }

    var pairWatchCandidates: [PairDeviceCandidate] {
      guard let snapshot else {
        return []
      }

      return Self.pairWatchCandidates(in: snapshot)
    }

    var presentedInstallAppTargetCandidates: [InstallAppTargetCandidate] {
      guard case .installAppOnSimulator(let formState) = lifecycleSheet else {
        return []
      }

      return installAppTargetCandidates(for: formState)
    }

    func installAppTargetCandidates(
      for formState: InstallAppTargetFormState
    ) -> [InstallAppTargetCandidate] {
      guard let snapshot,
            let sourceDevice = snapshot.devices.first(where: { $0.id == formState.sourceDeviceID })
      else {
        return []
      }

      return Self.installAppTargetCandidates(
        in: snapshot,
        sourceDevice: sourceDevice
      )
    }

    private var snapshot: SimulatorSnapshot? {
      workspace.snapshot
    }

    private static func initialCreateDeviceFormState(
      in snapshot: SimulatorSnapshot
    ) -> CreateDeviceFormState? {
      for runtime in snapshot.runtimes where runtime.isAvailable {
        guard let deviceType = compatibleDeviceTypes(
          for: runtime,
          in: snapshot.deviceTypes
        ).first else {
          continue
        }

        return CreateDeviceFormState(
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
    ) -> PairDevicesFormState? {
      let phoneCandidates = pairPhoneCandidates(in: snapshot)
      let watchCandidates = pairWatchCandidates(in: snapshot)

      guard !phoneCandidates.isEmpty, !watchCandidates.isEmpty else {
        return nil
      }

      let selectedPhoneID = phoneCandidates.first { $0.id == selectedDeviceID }?.id
      let selectedWatchID = watchCandidates.first { $0.id == selectedDeviceID }?.id

      return PairDevicesFormState(
        phoneDeviceID: selectedPhoneID ?? phoneCandidates[0].id,
        watchDeviceID: selectedWatchID ?? watchCandidates[0].id
      )
    }

    private static func pairPhoneCandidates(
      in snapshot: SimulatorSnapshot
    ) -> [PairDeviceCandidate] {
      snapshot.devices
        .filter { isPairPhoneCandidate($0, in: snapshot) }
        .map { PairDeviceCandidate(device: $0) }
    }

    private static func pairWatchCandidates(
      in snapshot: SimulatorSnapshot
    ) -> [PairDeviceCandidate] {
      let pairedWatchDeviceIDs = Set(snapshot.pairs.map(\.watchDeviceID))

      return snapshot.devices
        .filter {
          isPairWatchCandidate(
            $0,
            in: snapshot,
            pairedWatchDeviceIDs: pairedWatchDeviceIDs
          )
        }
        .map { PairDeviceCandidate(device: $0) }
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

    private static func installAppTargetCandidates(
      in snapshot: SimulatorSnapshot,
      sourceDevice: SimulatorDevice
    ) -> [InstallAppTargetCandidate] {
      snapshot.devices
        .filter { target in
          target.id != sourceDevice.id
            && target.isAvailable
            && target.platform == sourceDevice.platform
            && (target.state == .booted || target.state == .shutdown)
        }
        .map { InstallAppTargetCandidate(device: $0) }
    }
  }
}
