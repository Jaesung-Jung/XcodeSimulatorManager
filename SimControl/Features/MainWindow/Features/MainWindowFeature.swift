import ComposableArchitecture
import Foundation

@Reducer
struct MainWindowFeature {
  private static let menuBarAutoRefreshInterval: TimeInterval = 60

  @Dependency(\.appSandboxReset) private var appSandboxReset
  @Dependency(\.coreSimulatorService) private var coreSimulatorService
  @Dependency(\.pathAction) private var pathAction
  @Dependency(\.simulatorRepository) private var simulatorRepository

  private enum AppContainerPathTarget: Equatable, Sendable {
    case bundle
    case data
    case appGroup(String)

    var simctlContainer: CoreSimulatorService.AppContainerKind {
      switch self {
      case .bundle:
        .app
      case .data:
        .data
      case .appGroup(let groupID):
        .appGroup(groupID)
      }
    }

    var label: String {
      switch self {
      case .bundle:
        "app bundle container"
      case .data:
        "app data container"
      case .appGroup(let groupID):
        "App Group \(groupID) container"
      }
    }
  }

  private enum PathOperation: Equatable, Sendable {
    case open
    case copy
  }

  enum DeviceLifecycleSheet: Equatable, Identifiable {
    case create(CreateDeviceFormState)
    case clone(CloneDeviceFormState)
    case rename(RenameDeviceFormState)
    case erase(DeviceDestructiveConfirmationState)
    case delete(DeviceDestructiveConfirmationState)
    case pair(PairDevicesFormState)
    case unpair(UnpairDeviceConfirmationState)
    case uninstallApp(AppDestructiveConfirmationState)
    case resetAppSandbox(AppDestructiveConfirmationState)
    case installAppOnSimulator(InstallAppTargetFormState)

    var id: String {
      switch self {
      case .create:
        "create"
      case .clone(let formState):
        "clone-\(formState.sourceDeviceID)"
      case .rename(let formState):
        "rename-\(formState.deviceID)"
      case .erase(let confirmationState):
        "erase-\(confirmationState.deviceID)"
      case .delete(let confirmationState):
        "delete-\(confirmationState.deviceID)"
      case .pair:
        "pair"
      case .unpair(let confirmationState):
        "unpair-\(confirmationState.pairID)"
      case .uninstallApp(let confirmationState):
        "uninstall-app-\(confirmationState.appID)"
      case .resetAppSandbox(let confirmationState):
        "reset-app-sandbox-\(confirmationState.appID)"
      case .installAppOnSimulator(let formState):
        "install-app-\(formState.sourceAppID)"
      }
    }
  }

  struct DeviceDestructiveConfirmationState: Equatable {
    let deviceID: String
    let deviceName: String
    let deviceUDID: String
  }

  struct CreateDeviceFormState: Equatable {
    var name: String
    var runtimeID: String
    var deviceTypeID: String

    init(
      name: String = "",
      runtimeID: String = "",
      deviceTypeID: String = ""
    ) {
      self.name = name
      self.runtimeID = runtimeID
      self.deviceTypeID = deviceTypeID
    }
  }

  struct CloneDeviceFormState: Equatable {
    let sourceDeviceID: String
    let sourceName: String
    var name: String
  }

  struct RenameDeviceFormState: Equatable {
    let deviceID: String
    let currentName: String
    var name: String
  }

  struct PairDeviceCandidate: Equatable, Identifiable {
    let id: String
    let name: String
    let udid: String

    init(device: SimulatorDevice) {
      self.id = device.id
      self.name = device.name
      self.udid = device.udid
    }
  }

  struct PairDevicesFormState: Equatable {
    var phoneDeviceID: String
    var watchDeviceID: String
  }

  struct UnpairDeviceConfirmationState: Equatable {
    let pairID: String
    let phoneName: String
    let phoneUDID: String
    let watchName: String
    let watchUDID: String
  }

  struct AppDestructiveConfirmationState: Equatable {
    let appID: String
    let appName: String
    let bundleID: String
    let deviceID: String
    let deviceName: String
    let deviceUDID: String
    let dataContainerPath: String?
  }

  struct InstallAppTargetCandidate: Equatable, Identifiable {
    let id: String
    let name: String
    let udid: String
    let state: SimulatorDevice.State

    init(device: SimulatorDevice) {
      self.id = device.id
      self.name = device.name
      self.udid = device.udid
      self.state = device.state
    }
  }

  struct InstallAppTargetFormState: Equatable {
    let sourceAppID: String
    let sourceDeviceID: String
    let appName: String
    let bundleID: String
    let appBundlePath: URL
    var targetDeviceID: String
    var launchAfterInstall: Bool
  }

  @ObservableState
  struct State: Equatable {
    var lastMenuBarAutoRefreshAttemptAt: Date?
    var lifecycleSheet: DeviceLifecycleSheet?
    var sidebar: SidebarFeature.State
    var workspace: WorkspaceFeature.State

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
        isOpeningSimulatorApp: isOpeningSimulatorApp
      )
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

  enum Action: Equatable {
    case task
    case menuBarPresented(at: Date)
    case refreshButtonTapped
    case refreshResponse(SimulatorRepository.RefreshResult)
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
      SimulatorRepository.RefreshResult,
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
      SimulatorRepository.RefreshResult,
      preferredSelectedDeviceID: String?,
      preferredSelectedAppID: String?
    )
    case sidebar(SidebarFeature.Action)
    case workspace(WorkspaceFeature.Action)
  }

  var body: some ReducerOf<Self> {
    Reduce { state, action in
      switch action {
      case .task:
        guard state.workspace.snapshot == nil else {
          return .none
        }

        return refresh(&state)

      case .menuBarPresented(let date):
        return autoRefreshFromMenuBar(&state, at: date)

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
  }

  private func autoRefreshFromMenuBar(
    _ state: inout State,
    at date: Date
  ) -> Effect<Action> {
    guard state.workspace.refreshState != .refreshing,
          snapshotNeedsMenuBarRefresh(state.workspace.snapshot, at: date),
          canAttemptMenuBarAutoRefresh(state, at: date)
    else {
      return .none
    }

    state.lastMenuBarAutoRefreshAttemptAt = date
    return refresh(&state)
  }

  private func refresh(_ state: inout State) -> Effect<Action> {
    guard state.workspace.refreshState != .refreshing else {
      return .none
    }

    state.sidebar.refreshState = .refreshing
    state.workspace.setRefreshState(.refreshing)

    return .run { [simulatorRepository] send in
      await send(.refreshResponse(await simulatorRepository.refresh()))
    }
  }

  private func openSimulatorApp(_ state: inout State) -> Effect<Action> {
    guard !state.workspace.isOpeningSimulatorApp else {
      return .none
    }

    state.workspace.setOpeningSimulatorApp(true)

    return .run { [coreSimulatorService] send in
      let commandResult = await coreSimulatorService.openSimulatorApp()
      await send(.openSimulatorAppResponse(commandResult))
    }
  }

  private func runDeviceCommand(
    _ state: inout State,
    _ deviceCommandState: DeviceCommandState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let deviceID = deviceCommandState.deviceID,
          let device = device(id: deviceID, in: state),
          canRun(deviceCommandState.command, on: device)
    else {
      return .none
    }

    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult: CommandResult

      switch deviceCommandState.command {
      case .boot:
        commandResult = await coreSimulatorService.bootDevice(deviceID)
      case .shutdown:
        commandResult = await coreSimulatorService.shutdownDevice(deviceID)
      case .create, .clone, .rename, .erase, .delete, .pair, .unpair:
        return
      }

      await send(.deviceCommandResponse(deviceCommandState, commandResult))
      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runCreateDeviceCommand(
    _ state: inout State,
    formState: CreateDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let snapshot = state.workspace.snapshot,
          let runtime = snapshot.runtimes.first(where: { $0.id == formState.runtimeID && $0.isAvailable }),
          let deviceType = compatibleDeviceTypes(for: runtime, in: snapshot.deviceTypes)
            .first(where: { $0.id == formState.deviceTypeID })
    else {
      return .none
    }

    let name = nonEmpty(formState.name) ?? deviceType.name
    guard !name.isEmpty else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .create)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.createDevice(
        name,
        deviceType.id,
        runtime.id
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: Self.preferredDeviceID(from: commandResult)
        )
      )
    }
  }

  private func runCloneDeviceCommand(
    _ state: inout State,
    formState: CloneDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          device(id: formState.sourceDeviceID, in: state) != nil,
          let name = nonEmpty(formState.name)
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .clone,
      deviceID: formState.sourceDeviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.cloneDevice(
        formState.sourceDeviceID,
        name
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: Self.preferredDeviceID(from: commandResult)
        )
      )
    }
  }

  private func runRenameDeviceCommand(
    _ state: inout State,
    formState: RenameDeviceFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          device(id: formState.deviceID, in: state) != nil,
          let name = nonEmpty(formState.name),
          name != formState.currentName
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .rename,
      deviceID: formState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.renameDevice(
        formState.deviceID,
        name
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runEraseDeviceCommand(
    _ state: inout State,
    confirmationState: DeviceDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = device(id: confirmationState.deviceID, in: state),
          device.isAvailable,
          device.udid == confirmationState.deviceUDID
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .erase,
      deviceID: confirmationState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.eraseDevice(confirmationState.deviceID)
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runDeleteDeviceCommand(
    _ state: inout State,
    confirmationState: DeviceDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let device = device(id: confirmationState.deviceID, in: state),
          device.udid == confirmationState.deviceUDID
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(
      command: .delete,
      deviceID: confirmationState.deviceID
    )
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.deleteDevice(confirmationState.deviceID)
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runPairDevicesCommand(
    _ state: inout State,
    formState: PairDevicesFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          state.pairPhoneCandidates.contains(where: { $0.id == formState.phoneDeviceID }),
          state.pairWatchCandidates.contains(where: { $0.id == formState.watchDeviceID })
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .pair)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.pairDevices(
        formState.watchDeviceID,
        formState.phoneDeviceID
      )
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runUnpairDeviceCommand(
    _ state: inout State,
    confirmationState: UnpairDeviceConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          unpairConfirmationState(pairID: confirmationState.pairID, in: state) == confirmationState
    else {
      return .none
    }

    let deviceCommandState = DeviceCommandState(command: .unpair)
    state.workspace.setDeviceCommandState(deviceCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResult = await coreSimulatorService.unpairDevice(confirmationState.pairID)
      await send(.deviceCommandResponse(deviceCommandState, commandResult))

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .deviceCommandRefreshResponse(
          deviceCommandState,
          refreshResult,
          preferredSelectedDeviceID: nil
        )
      )
    }
  }

  private func runLaunchAppCommand(
    _ state: inout State,
    appID: String
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: appID, in: state),
          canLaunchApp(context.app, on: context.device)
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .launch,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      var commandResults: [CommandResult] = []

      if context.device.state == .shutdown {
        let bootResult = await coreSimulatorService.bootDeviceIfNeeded(context.device.id)
        commandResults.append(bootResult)

        guard bootResult.succeeded else {
          await send(
            .appCommandCommandsCompleted(
              appCommandState,
              commandResults,
              preferredSelectedDeviceID: context.device.id,
              preferredSelectedAppID: context.app.id
            )
          )
          let refreshResult = await simulatorRepository.refresh()
          await send(
            .appCommandRefreshResponse(
              appCommandState,
              refreshResult,
              preferredSelectedDeviceID: context.device.id,
              preferredSelectedAppID: context.app.id
            )
          )
          return
        }
      }

      commandResults.append(
        await coreSimulatorService.launchApp(
          context.device.id,
          context.app.bundleID
        )
      )
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          commandResults,
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: context.app.id
        )
      )

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .appCommandRefreshResponse(
          appCommandState,
          refreshResult,
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: context.app.id
        )
      )
    }
  }

  private func runTerminateAppCommand(
    _ state: inout State,
    appID: String
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: appID, in: state),
          canTerminateApp(context.app, on: context.device)
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .terminate,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let commandResults = [
        await coreSimulatorService.terminateApp(
          context.device.id,
          context.app.bundleID
        )
      ]
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          commandResults,
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: context.app.id
        )
      )

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .appCommandRefreshResponse(
          appCommandState,
          refreshResult,
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: context.app.id
        )
      )
    }
  }

  private func runUninstallAppCommand(
    _ state: inout State,
    confirmationState: AppDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: confirmationState.appID, in: state),
          canUninstallApp(context.app, on: context.device),
          appDestructiveConfirmationState(
            appID: confirmationState.appID,
            in: state,
            includesDataContainer: false
          ) == confirmationState
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .uninstall,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      let uninstallResult = await coreSimulatorService.uninstallApp(
        context.device.id,
        context.app.bundleID
      )
      let preferredSelectedAppID = uninstallResult.succeeded ? nil : context.app.id

      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          [uninstallResult],
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: preferredSelectedAppID
        )
      )

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .appCommandRefreshResponse(
          appCommandState,
          refreshResult,
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: preferredSelectedAppID
        )
      )
    }
  }

  private func runResetAppSandboxCommand(
    _ state: inout State,
    confirmationState: AppDestructiveConfirmationState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: confirmationState.appID, in: state),
          let dataContainer = context.app.dataContainer,
          appDestructiveConfirmationState(
            appID: confirmationState.appID,
            in: state,
            includesDataContainer: true
          ) == confirmationState
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .resetSandbox,
      sourceDeviceID: context.device.id,
      appID: context.app.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [appSandboxReset, simulatorRepository] send in
      let resetResult = await appSandboxReset.resetSandbox(dataContainer)
      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          [resetResult],
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: context.app.id
        )
      )

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .appCommandRefreshResponse(
          appCommandState,
          refreshResult,
          preferredSelectedDeviceID: context.device.id,
          preferredSelectedAppID: context.app.id
        )
      )
    }
  }

  private func runInstallAppOnSimulatorCommand(
    _ state: inout State,
    formState: InstallAppTargetFormState
  ) -> Effect<Action> {
    guard state.workspace.deviceCommandState == nil,
          state.workspace.appCommandState == nil,
          let context = appCommandContext(appID: formState.sourceAppID, in: state),
          let appBundlePath = context.app.appBundlePath,
          appBundlePath == formState.appBundlePath,
          context.app.bundleID == formState.bundleID,
          context.device.id == formState.sourceDeviceID,
          let targetDevice = installTargetDevice(id: formState.targetDeviceID, sourceDevice: context.device, in: state)
    else {
      return .none
    }

    let appCommandState = AppCommandState(
      command: .installOnSimulator,
      sourceDeviceID: context.device.id,
      appID: context.app.id,
      targetDeviceID: targetDevice.id
    )
    state.workspace.setAppCommandState(appCommandState)

    return .run { [coreSimulatorService, simulatorRepository] send in
      var commandResults: [CommandResult] = []
      var installed = false

      if targetDevice.state == .shutdown {
        let bootResult = await coreSimulatorService.bootDeviceIfNeeded(targetDevice.id)
        commandResults.append(bootResult)

        guard bootResult.succeeded else {
          await send(
            .appCommandCommandsCompleted(
              appCommandState,
              commandResults,
              preferredSelectedDeviceID: nil,
              preferredSelectedAppID: nil
            )
          )
          let refreshResult = await simulatorRepository.refresh()
          await send(
            .appCommandRefreshResponse(
              appCommandState,
              refreshResult,
              preferredSelectedDeviceID: nil,
              preferredSelectedAppID: nil
            )
          )
          return
        }
      }

      let installResult = await coreSimulatorService.installApp(
        targetDevice.id,
        appBundlePath
      )
      commandResults.append(installResult)
      installed = installResult.succeeded

      if installed, formState.launchAfterInstall {
        commandResults.append(
          await coreSimulatorService.launchApp(
            targetDevice.id,
            context.app.bundleID
          )
        )
      }

      let preferredSelectedDeviceID = installed ? targetDevice.id : nil
      let preferredSelectedAppID = installed
        ? "\(targetDevice.id):\(context.app.bundleID)"
        : nil

      await send(
        .appCommandCommandsCompleted(
          appCommandState,
          commandResults,
          preferredSelectedDeviceID: preferredSelectedDeviceID,
          preferredSelectedAppID: preferredSelectedAppID
        )
      )

      let refreshResult = await simulatorRepository.refresh()
      await send(
        .appCommandRefreshResponse(
          appCommandState,
          refreshResult,
          preferredSelectedDeviceID: preferredSelectedDeviceID,
          preferredSelectedAppID: preferredSelectedAppID
        )
      )
    }
  }

  private func runDevicePathAction(
    _ state: inout State,
    deviceID: String,
    path: (SimulatorDevice) -> URL?,
    label: String,
    operation: PathOperation
  ) -> Effect<Action> {
    guard let device = device(id: deviceID, in: state) else {
      return .none
    }

    let url = path(device)
    return .run { [pathAction] send in
      let result: CommandResult

      switch operation {
      case .open:
        result = await pathAction.openInFinder(url, label)
      case .copy:
        result = await pathAction.copyPath(url, label)
      }

      await send(.pathActionResults([result]))
    }
  }

  private func runDeviceValueCopyAction(
    _ state: inout State,
    deviceID: String,
    value: (SimulatorDevice) -> String?,
    label: String
  ) -> Effect<Action> {
    guard let device = device(id: deviceID, in: state) else {
      return .none
    }

    let value = value(device)
    return .run { [pathAction] send in
      let result = await pathAction.copy(value, label)
      await send(.pathActionResults([result]))
    }
  }

  private func runAppValueCopyAction(
    _ state: inout State,
    appID: String,
    value: (InstalledApp) -> String?,
    label: String
  ) -> Effect<Action> {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return .none
    }

    let value = value(context.app)
    return .run { [pathAction] send in
      let result = await pathAction.copy(value, label)
      await send(.pathActionResults([result]))
    }
  }

  private func runAppContainerPathAction(
    _ state: inout State,
    appID: String,
    target: AppContainerPathTarget,
    operation: PathOperation
  ) -> Effect<Action> {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return .none
    }

    let deviceID = context.device.id
    let bundleID = context.app.bundleID
    let fallbackURL = fallbackContainerURL(for: target, app: context.app)
    let label = target.label
    let simctlContainer = target.simctlContainer

    return .run { [coreSimulatorService, pathAction] send in
      var results: [CommandResult] = []
      let getContainerResult = await coreSimulatorService.getAppContainer(
        deviceID,
        bundleID,
        simctlContainer
      )
      results.append(getContainerResult)

      let resolvedURL = Self.containerURL(
        from: getContainerResult,
        target: target
      ) ?? fallbackURL
      let actionResult: CommandResult

      switch operation {
      case .open:
        actionResult = await pathAction.openInFinder(resolvedURL, label)
      case .copy:
        actionResult = await pathAction.copyPath(resolvedURL, label)
      }

      results.append(actionResult)
      await send(.pathActionResults(results))
    }
  }

  private func fallbackContainerURL(
    for target: AppContainerPathTarget,
    app: InstalledApp
  ) -> URL? {
    switch target {
    case .bundle:
      app.bundleContainer ?? app.appBundlePath?.deletingLastPathComponent()
    case .data:
      app.dataContainer
    case .appGroup(let groupID):
      app.appGroups.first { $0.groupID == groupID }?.path
    }
  }

  private static func containerURL(
    from result: CommandResult,
    target: AppContainerPathTarget
  ) -> URL? {
    guard result.succeeded else {
      return nil
    }

    let path = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !path.isEmpty else {
      return nil
    }

    let url = URL(fileURLWithPath: path)
    if target == .bundle && url.pathExtension == "app" {
      return url.deletingLastPathComponent()
    }

    return url
  }

  private func snapshotNeedsMenuBarRefresh(
    _ snapshot: SimulatorSnapshot?,
    at date: Date
  ) -> Bool {
    guard let snapshot else {
      return true
    }

    return date.timeIntervalSince(snapshot.generatedAt) >= Self.menuBarAutoRefreshInterval
  }

  private func canAttemptMenuBarAutoRefresh(
    _ state: State,
    at date: Date
  ) -> Bool {
    guard let lastMenuBarAutoRefreshAttemptAt = state.lastMenuBarAutoRefreshAttemptAt else {
      return true
    }

    return date.timeIntervalSince(lastMenuBarAutoRefreshAttemptAt) >= Self.menuBarAutoRefreshInterval
  }

  private func device(id: String, in state: State) -> SimulatorDevice? {
    state.workspace.snapshot?.devices.first { $0.id == id }
  }

  private func deviceDestructiveConfirmationState(
    deviceID: String,
    in state: State
  ) -> DeviceDestructiveConfirmationState? {
    guard let device = device(id: deviceID, in: state) else {
      return nil
    }

    return DeviceDestructiveConfirmationState(
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid
    )
  }

  private func unpairConfirmationState(
    pairID: String,
    in state: State
  ) -> UnpairDeviceConfirmationState? {
    guard let snapshot = state.workspace.snapshot,
          let pair = snapshot.pairs.first(where: { $0.id == pairID }),
          let phoneDevice = snapshot.devices.first(where: { $0.id == pair.phoneDeviceID }),
          let watchDevice = snapshot.devices.first(where: { $0.id == pair.watchDeviceID })
    else {
      return nil
    }

    return UnpairDeviceConfirmationState(
      pairID: pair.id,
      phoneName: phoneDevice.name,
      phoneUDID: phoneDevice.udid,
      watchName: watchDevice.name,
      watchUDID: watchDevice.udid
    )
  }

  private struct AppCommandContext {
    let device: SimulatorDevice
    let app: InstalledApp
  }

  private func appCommandContext(
    appID: String,
    in state: State
  ) -> AppCommandContext? {
    guard let selectedDevice = state.workspace.selectedDevice,
          let app = state.workspace.snapshot?.installedAppsByDeviceID[selectedDevice.id]?
            .first(where: { $0.id == appID }),
          app.deviceID == selectedDevice.id
    else {
      return nil
    }

    return AppCommandContext(device: selectedDevice, app: app)
  }

  private func appDestructiveConfirmationState(
    appID: String,
    in state: State,
    includesDataContainer: Bool
  ) -> AppDestructiveConfirmationState? {
    guard let context = appCommandContext(appID: appID, in: state) else {
      return nil
    }

    return AppDestructiveConfirmationState(
      appID: context.app.id,
      appName: context.app.displayName,
      bundleID: context.app.bundleID,
      deviceID: context.device.id,
      deviceName: context.device.name,
      deviceUDID: context.device.udid,
      dataContainerPath: includesDataContainer ? context.app.dataContainer?.path : nil
    )
  }

  private func installAppTargetFormState(
    appID: String,
    in state: State
  ) -> InstallAppTargetFormState? {
    guard let context = appCommandContext(appID: appID, in: state),
          let appBundlePath = context.app.appBundlePath,
          let targetDevice = installTargetCandidates(sourceDevice: context.device, in: state).first
    else {
      return nil
    }

    return InstallAppTargetFormState(
      sourceAppID: context.app.id,
      sourceDeviceID: context.device.id,
      appName: context.app.displayName,
      bundleID: context.app.bundleID,
      appBundlePath: appBundlePath,
      targetDeviceID: targetDevice.id,
      launchAfterInstall: true
    )
  }

  private func installTargetDevice(
    id: String,
    sourceDevice: SimulatorDevice,
    in state: State
  ) -> SimulatorDevice? {
    installTargetCandidates(sourceDevice: sourceDevice, in: state)
      .first { $0.id == id }
  }

  private func installTargetCandidates(
    sourceDevice: SimulatorDevice,
    in state: State
  ) -> [SimulatorDevice] {
    (state.workspace.snapshot?.devices ?? []).filter { target in
      target.id != sourceDevice.id
        && target.isAvailable
        && target.platform == sourceDevice.platform
        && (target.state == .booted || target.state == .shutdown)
    }
  }

  private func canLaunchApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && (device.state == .booted || device.state == .shutdown)
  }

  private func canTerminateApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && device.state == .booted
  }

  private func canUninstallApp(
    _ app: InstalledApp,
    on device: SimulatorDevice
  ) -> Bool {
    !app.bundleID.isEmpty
      && device.isAvailable
      && (device.state == .booted || device.state == .shutdown)
  }

  private func canRun(
    _ command: DeviceCommand,
    on device: SimulatorDevice
  ) -> Bool {
    guard device.isAvailable else {
      return false
    }

    switch command {
    case .boot:
      return device.state == .shutdown
    case .shutdown:
      return device.state == .booted
    case .create, .clone, .rename, .erase, .delete, .pair, .unpair:
      return false
    }
  }

  private func compatibleDeviceTypes(
    for runtime: SimulatorRuntime,
    in deviceTypes: [SimulatorDeviceType]
  ) -> [SimulatorDeviceType] {
    guard !runtime.supportedDeviceTypeIDs.isEmpty else {
      return deviceTypes
    }

    let supportedDeviceTypeIDs = Set(runtime.supportedDeviceTypeIDs)
    return deviceTypes.filter { supportedDeviceTypeIDs.contains($0.id) }
  }

  private func nonEmpty(_ value: String) -> String? {
    let trimmedValue = value.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedValue.isEmpty ? nil : trimmedValue
  }

  private static func preferredDeviceID(from result: CommandResult) -> String? {
    guard result.succeeded else {
      return nil
    }

    return result.stdout
      .split(whereSeparator: \.isNewline)
      .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
      .first { !$0.isEmpty }
  }

  private func commandResults(
    from result: SimulatorRepository.RefreshResult
  ) -> [CommandResult] {
    var results = [result.xcodeCommandResult]

    if let listCommandResult = result.listCommandResult {
      results.append(listCommandResult)
    }

    return results
  }
}
