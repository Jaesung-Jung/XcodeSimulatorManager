import ComposableArchitecture
import DeveloperToolsFeature
import DeviceDetailFeature
import DeviceListFeature
import InspectorFeature
import MainWindowFeatureSupport
import MainWindowWorkflows
import MenuBarFeature
import SidebarFeature
import SimControlClients
import SimControlDomain
import Foundation
import WorkspaceFeature

@Reducer
public struct MainWindowFeature {
  static let menuBarAutoRefreshInterval: TimeInterval = 60

  @Dependency(\.appSandboxReset) var appSandboxReset
  @Dependency(\.coreSimulatorService) var coreSimulatorService
  @Dependency(\.pathAction) var pathAction
  @Dependency(\.simulatorRepository) var simulatorRepository

  public init() {}

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

  public enum Action: Equatable {
    case task
    case menuBar(MenuBarFeature.Action)
    case refreshButtonTapped
    case refreshResponse(SimulatorRefreshResult)
    case createSimulatorButtonTapped
    case cloneSelectedSimulatorButtonTapped
    case pairDevicesButtonTapped
    case lifecycleSheetDismissed
    case createDeviceSubmitted(CreateDeviceFormState)
    case cloneDeviceSubmitted(CloneDeviceFormState)
    case renameDeviceSubmitted(RenameDeviceFormState)
    case eraseDeviceConfirmed(DeviceDestructiveConfirmationState)
    case deleteDeviceConfirmed(DeviceDestructiveConfirmationState)
    case pairDevicesSubmitted(PairDevicesFormState)
    case unpairDeviceConfirmed(UnpairDeviceConfirmationState)
    case uninstallAppConfirmed(AppDestructiveConfirmationState)
    case resetAppSandboxConfirmed(AppDestructiveConfirmationState)
    case installAppOnSimulatorSubmitted(InstallAppTargetFormState)
    case openSimulatorAppButtonTapped
    case openSimulatorAppResponse(CommandResult)
    case pathActionResults([CommandResult])
    case deviceCommandResponse(DeviceCommandState, CommandResult)
    case deviceCommandRefreshResponse(
      DeviceCommandState,
      SimulatorRefreshResult,
      preferredSelectedDeviceID: String?
    )
    case appCommandCommandsCompleted(
      AppCommandState,
      [CommandResult],
      preferredSelectedDeviceID: String?,
      preferredSelectedAppID: String?
    )
    case appCommandRefreshResponse(
      AppCommandState,
      SimulatorRefreshResult,
      preferredSelectedDeviceID: String?,
      preferredSelectedAppID: String?
    )
    case developerToolCommandResults(
      DeviceCommandState,
      [CommandResult],
      refreshAfterward: Bool
    )
    case developerToolCommandRefreshResponse(
      DeviceCommandState,
      SimulatorRefreshResult,
      preferredSelectedDeviceID: String?
    )
    case sidebar(SidebarFeature.Action)
    case workspace(WorkspaceFeature.Action)
  }

  public var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard state.workspace.snapshot == nil else {
          return .none
        }

        return refresh(&state)

      case .menuBar(.presented(let date)):
        return autoRefreshFromMenuBar(&state, at: date)

      case .menuBar(.refreshButtonTapped):
        return refresh(&state)

      case .menuBar(.openSimulatorAppButtonTapped):
        return openSimulatorApp(&state)

      case .menuBar(.deviceSelected(let deviceID)):
        state.workspace.selectDevice(id: deviceID)
        return .none

      case .menuBar(.appSelected(let deviceID, let appID)):
        state.workspace.selectDevice(id: deviceID)
        state.workspace.selectApp(id: appID)
        return .none

      case .refreshButtonTapped:
        return refresh(&state)

      case .refreshResponse(let result):
        let commandResults = commandResults(from: result)

        if let snapshot = result.snapshot, result.diagnostic == nil {
          state.sidebar.snapshot = snapshot
          state.sidebar.refreshState = .idle
          state.workspace.applySnapshot(
            snapshot,
            refreshState: .idle,
            commandResults: commandResults
          )
        } else {
          let refreshState = InventoryRefreshState.failed(
            diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
          )
          state.sidebar.refreshState = refreshState
          state.workspace.applyRefreshFailure(
            refreshState,
            commandResults: commandResults
          )
        }

        return .none

      case .createSimulatorButtonTapped:
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let formState = state.initialCreateDeviceFormState
        else {
          return .none
        }

        state.lifecycleSheet = .create(formState)
        return .none

      case .cloneSelectedSimulatorButtonTapped:
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let device = state.workspace.selectedDevice
        else {
          return .none
        }

        state.lifecycleSheet = .clone(
          CloneDeviceFormState(
            sourceDeviceID: device.id,
            sourceName: device.name,
            name: "\(device.name) Copy"
          )
        )
        return .none

      case .pairDevicesButtonTapped:
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let formState = state.initialPairDevicesFormState
        else {
          return .none
        }

        state.lifecycleSheet = .pair(formState)
        return .none

      case .lifecycleSheetDismissed:
        state.lifecycleSheet = nil
        return .none

      case .createDeviceSubmitted(let formState):
        state.lifecycleSheet = nil
        return runCreateDeviceCommand(&state, formState: formState)

      case .cloneDeviceSubmitted(let formState):
        state.lifecycleSheet = nil
        return runCloneDeviceCommand(&state, formState: formState)

      case .renameDeviceSubmitted(let formState):
        state.lifecycleSheet = nil
        return runRenameDeviceCommand(&state, formState: formState)

      case .eraseDeviceConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runEraseDeviceCommand(&state, confirmationState: confirmationState)

      case .deleteDeviceConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runDeleteDeviceCommand(&state, confirmationState: confirmationState)

      case .pairDevicesSubmitted(let formState):
        state.lifecycleSheet = nil
        return runPairDevicesCommand(&state, formState: formState)

      case .unpairDeviceConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runUnpairDeviceCommand(&state, confirmationState: confirmationState)

      case .uninstallAppConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runUninstallAppCommand(&state, confirmationState: confirmationState)

      case .resetAppSandboxConfirmed(let confirmationState):
        state.lifecycleSheet = nil
        return runResetAppSandboxCommand(&state, confirmationState: confirmationState)

      case .installAppOnSimulatorSubmitted(let formState):
        state.lifecycleSheet = nil
        return runInstallAppOnSimulatorCommand(&state, formState: formState)

      case .openSimulatorAppButtonTapped:
        return openSimulatorApp(&state)

      case .openSimulatorAppResponse(let result):
        state.workspace.appendCommandResult(result)
        state.workspace.setOpeningSimulatorApp(false)
        return .none

      case .pathActionResults(let results):
        for result in results {
          state.workspace.appendCommandResult(result)
        }
        return .none

      case .developerToolCommandResults(let deviceCommandState, let results, let refreshAfterward):
        guard state.workspace.deviceCommandState == deviceCommandState else {
          return .none
        }

        for result in results {
          state.workspace.appendCommandResult(result)
        }

        if refreshAfterward {
          state.sidebar.refreshState = .refreshing
          state.workspace.setRefreshState(.refreshing)
        } else {
          state.workspace.setDeviceCommandState(nil)
        }

        return .none

      case .developerToolCommandRefreshResponse(
        let deviceCommandState,
        let result,
        let preferredSelectedDeviceID
      ):
        guard state.workspace.deviceCommandState == deviceCommandState else {
          return .none
        }

        let commandResults = state.workspace.commandResults + commandResults(from: result)

        if let snapshot = result.snapshot, result.diagnostic == nil {
          state.sidebar.snapshot = snapshot
          state.sidebar.refreshState = .idle
          state.workspace.applySnapshot(
            snapshot,
            refreshState: .idle,
            commandResults: commandResults,
            preferredSelectedDeviceID: preferredSelectedDeviceID
          )
        } else {
          let refreshState = InventoryRefreshState.failed(
            diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
          )
          state.sidebar.refreshState = refreshState
          state.workspace.applyRefreshFailure(
            refreshState,
            commandResults: commandResults
          )
        }

        state.workspace.setDeviceCommandState(nil)
        return .none

      case .deviceCommandResponse(let deviceCommandState, let result):
        guard state.workspace.deviceCommandState == deviceCommandState else {
          return .none
        }

        state.workspace.appendCommandResult(result)
        state.sidebar.refreshState = .refreshing
        state.workspace.setRefreshState(.refreshing)
        return .none

      case .deviceCommandRefreshResponse(let deviceCommandState, let result, let preferredSelectedDeviceID):
        guard state.workspace.deviceCommandState == deviceCommandState else {
          return .none
        }

        let commandResults = state.workspace.commandResults + commandResults(from: result)

        if let snapshot = result.snapshot, result.diagnostic == nil {
          state.sidebar.snapshot = snapshot
          state.sidebar.refreshState = .idle
          state.workspace.applySnapshot(
            snapshot,
            refreshState: .idle,
            commandResults: commandResults,
            preferredSelectedDeviceID: preferredSelectedDeviceID
          )
        } else {
          let refreshState = InventoryRefreshState.failed(
            diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
          )
          state.sidebar.refreshState = refreshState
          state.workspace.applyRefreshFailure(
            refreshState,
            commandResults: commandResults
          )
        }

        state.workspace.setDeviceCommandState(nil)
        return .none

      case .appCommandCommandsCompleted(
        let appCommandState,
        let commandResults,
        preferredSelectedDeviceID: _,
        preferredSelectedAppID: _
      ):
        guard state.workspace.appCommandState == appCommandState else {
          return .none
        }

        for commandResult in commandResults {
          state.workspace.appendCommandResult(commandResult)
        }
        state.sidebar.refreshState = .refreshing
        state.workspace.setRefreshState(.refreshing)
        return .none

      case .appCommandRefreshResponse(
        let appCommandState,
        let result,
        let preferredSelectedDeviceID,
        let preferredSelectedAppID
      ):
        guard state.workspace.appCommandState == appCommandState else {
          return .none
        }

        let commandResults = state.workspace.commandResults + commandResults(from: result)

        if let snapshot = result.snapshot, result.diagnostic == nil {
          state.sidebar.snapshot = snapshot
          state.sidebar.refreshState = .idle
          state.workspace.applySnapshot(
            snapshot,
            refreshState: .idle,
            commandResults: commandResults,
            preferredSelectedDeviceID: preferredSelectedDeviceID,
            preferredSelectedAppID: preferredSelectedAppID
          )
        } else {
          let refreshState = InventoryRefreshState.failed(
            diagnostic: result.diagnostic ?? "Unable to refresh simulator inventory."
          )
          state.sidebar.refreshState = refreshState
          state.workspace.applyRefreshFailure(
            refreshState,
            commandResults: commandResults
          )
        }

        state.workspace.setAppCommandState(nil)
        return .none

      case .workspace(.deviceDetail(.bootButtonTapped(let deviceID))):
        return runDeviceCommand(
          &state,
          DeviceCommandState(command: .boot, deviceID: deviceID)
        )

      case .workspace(.deviceDetail(.shutdownButtonTapped(let deviceID))):
        return runDeviceCommand(
          &state,
          DeviceCommandState(command: .shutdown, deviceID: deviceID)
        )

      case .workspace(.deviceDetail(.openSimulatorAppButtonTapped)):
        return openSimulatorApp(&state)

      case .workspace(.deviceDetail(.renameButtonTapped(let deviceID))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let device = device(id: deviceID, in: state)
        else {
          return .none
        }

        state.lifecycleSheet = .rename(
          RenameDeviceFormState(
            deviceID: device.id,
            currentName: device.name,
            name: device.name
          )
        )
        return .none

      case .workspace(.deviceDetail(.eraseButtonTapped(let deviceID))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let confirmationState = deviceDestructiveConfirmationState(
                deviceID: deviceID,
                in: state
              )
        else {
          return .none
        }

        state.lifecycleSheet = .erase(confirmationState)
        return .none

      case .workspace(.deviceDetail(.deleteButtonTapped(let deviceID))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let confirmationState = deviceDestructiveConfirmationState(
                deviceID: deviceID,
                in: state
              )
        else {
          return .none
        }

        state.lifecycleSheet = .delete(confirmationState)
        return .none

      case .workspace(.deviceDetail(.unpairButtonTapped(let pairID))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let confirmationState = unpairConfirmationState(pairID: pairID, in: state)
        else {
          return .none
        }

        state.lifecycleSheet = .unpair(confirmationState)
        return .none

      case .workspace(.deviceDetail(.openDeviceDataFolderButtonTapped(let deviceID))),
           .workspace(.inspector(.openDeviceDataFolderButtonTapped(let deviceID))):
        return runDevicePathAction(
          &state,
          deviceID: deviceID,
          path: { $0.dataPath },
          label: "device data folder",
          operation: .open
        )

      case .workspace(.deviceDetail(.copyDeviceDataPathButtonTapped(let deviceID))),
           .workspace(.inspector(.copyDeviceDataPathButtonTapped(let deviceID))):
        return runDevicePathAction(
          &state,
          deviceID: deviceID,
          path: { $0.dataPath },
          label: "device data path",
          operation: .copy
        )

      case .workspace(.deviceDetail(.openDeviceLogFolderButtonTapped(let deviceID))),
           .workspace(.inspector(.openDeviceLogFolderButtonTapped(let deviceID))):
        return runDevicePathAction(
          &state,
          deviceID: deviceID,
          path: { $0.logPath },
          label: "device log folder",
          operation: .open
        )

      case .workspace(.deviceDetail(.copyDeviceLogPathButtonTapped(let deviceID))),
           .workspace(.inspector(.copyDeviceLogPathButtonTapped(let deviceID))):
        return runDevicePathAction(
          &state,
          deviceID: deviceID,
          path: { $0.logPath },
          label: "device log path",
          operation: .copy
        )

      case .workspace(.deviceDetail(.copyDeviceUDIDButtonTapped(let deviceID))),
           .workspace(.inspector(.copyDeviceUDIDButtonTapped(let deviceID))):
        return runDeviceValueCopyAction(
          &state,
          deviceID: deviceID,
          value: { $0.udid },
          label: "device UDID"
        )

      case .workspace(.deviceDetail(.copyRuntimeIdentifierButtonTapped(let deviceID))),
           .workspace(.inspector(.copyRuntimeIdentifierButtonTapped(let deviceID))):
        return runDeviceValueCopyAction(
          &state,
          deviceID: deviceID,
          value: { $0.runtimeID },
          label: "runtime identifier"
        )

      case .workspace(.deviceDetail(.copyDeviceTypeIdentifierButtonTapped(let deviceID))),
           .workspace(.inspector(.copyDeviceTypeIdentifierButtonTapped(let deviceID))):
        return runDeviceValueCopyAction(
          &state,
          deviceID: deviceID,
          value: { $0.deviceTypeID },
          label: "device type identifier"
        )

      case .workspace(.deviceDetail(.installedApps(.launchButtonTapped(let appID)))):
        return runLaunchAppCommand(&state, appID: appID)

      case .workspace(.deviceDetail(.installedApps(.terminateButtonTapped(let appID)))):
        return runTerminateAppCommand(&state, appID: appID)

      case .workspace(.deviceDetail(.installedApps(.uninstallButtonTapped(let appID)))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let confirmationState = appDestructiveConfirmationState(
                appID: appID,
                in: state,
                includesDataContainer: false
              )
        else {
          return .none
        }

        state.lifecycleSheet = .uninstallApp(confirmationState)
        return .none

      case .workspace(.deviceDetail(.installedApps(.resetSandboxButtonTapped(let appID)))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let confirmationState = appDestructiveConfirmationState(
                appID: appID,
                in: state,
                includesDataContainer: true
              ),
              confirmationState.dataContainerPath != nil
        else {
          return .none
        }

        state.lifecycleSheet = .resetAppSandbox(confirmationState)
        return .none

      case .workspace(.deviceDetail(.installedApps(.installOnAnotherSimulatorButtonTapped(let appID)))):
        guard state.workspace.deviceCommandState == nil,
              state.workspace.appCommandState == nil,
              let formState = installAppTargetFormState(appID: appID, in: state)
        else {
          return .none
        }

        state.lifecycleSheet = .installAppOnSimulator(formState)
        return .none

      case .workspace(.deviceDetail(.installedApps(.openBundleContainerButtonTapped(let appID)))),
           .workspace(.inspector(.openAppBundleContainerButtonTapped(let appID))):
        return runAppContainerPathAction(
          &state,
          appID: appID,
          target: .bundle,
          operation: .open
        )

      case .workspace(.deviceDetail(.installedApps(.copyBundleContainerButtonTapped(let appID)))),
           .workspace(.inspector(.copyAppBundleContainerButtonTapped(let appID))):
        return runAppContainerPathAction(
          &state,
          appID: appID,
          target: .bundle,
          operation: .copy
        )

      case .workspace(.deviceDetail(.installedApps(.openDataContainerButtonTapped(let appID)))),
           .workspace(.inspector(.openAppDataContainerButtonTapped(let appID))):
        return runAppContainerPathAction(
          &state,
          appID: appID,
          target: .data,
          operation: .open
        )

      case .workspace(.deviceDetail(.installedApps(.copyDataContainerButtonTapped(let appID)))),
           .workspace(.inspector(.copyAppDataContainerButtonTapped(let appID))):
        return runAppContainerPathAction(
          &state,
          appID: appID,
          target: .data,
          operation: .copy
        )

      case .workspace(.deviceDetail(.installedApps(.copyBundleIDButtonTapped(let appID)))),
           .workspace(.inspector(.copyAppBundleIDButtonTapped(let appID))):
        return runAppValueCopyAction(
          &state,
          appID: appID,
          value: { $0.bundleID },
          label: "app bundle identifier"
        )

      case .workspace(.deviceDetail(.installedApps(.openAppGroupContainerButtonTapped(let appID, let groupID)))),
           .workspace(.inspector(.openAppGroupContainerButtonTapped(let appID, let groupID))):
        return runAppContainerPathAction(
          &state,
          appID: appID,
          target: .appGroup(groupID),
          operation: .open
        )

      case .workspace(.deviceDetail(.installedApps(.copyAppGroupContainerButtonTapped(let appID, let groupID)))),
           .workspace(.inspector(.copyAppGroupContainerButtonTapped(let appID, let groupID))):
        return runAppContainerPathAction(
          &state,
          appID: appID,
          target: .appGroup(groupID),
          operation: .copy
        )

      case .workspace(.deviceDetail(.developerTools(.openDeepLinkButtonTapped))):
        return runOpenDeepLinkCommand(&state)

      case .workspace(.deviceDetail(.developerTools(.sendPushButtonTapped))):
        return runPushNotificationCommand(&state)

      case .workspace(.deviceDetail(.developerTools(.applyPrivacyButtonTapped))):
        return runPrivacyPermissionCommand(&state)

      case .workspace(.deviceDetail(.developerTools(.setLocationButtonTapped))):
        return runSetLocationCommand(&state)

      case .workspace(.deviceDetail(.developerTools(.clearLocationButtonTapped))):
        return runClearLocationCommand(&state)

      case .workspace(.deviceDetail(.developerTools(.setStatusBarOverrideButtonTapped))):
        return runSetStatusBarOverrideCommand(&state)

      case .workspace(.deviceDetail(.developerTools(.clearStatusBarOverrideButtonTapped))):
        return runClearStatusBarOverrideCommand(&state)

      case .sidebar, .workspace:
        return .none
      }
    }

    Scope(state: \.sidebar, action: \.sidebar) {
      SidebarFeature()
    }
    Scope(state: \.workspace, action: \.workspace) {
      WorkspaceFeature()
    }
    Scope(state: \.menuBar, action: \.menuBar) {
      MenuBarFeature()
    }
  }

}
