import ComposableArchitecture
import MainWindowFeatureSupport
import SidebarFeature
import SimControlDomain
import Testing
import WorkspaceFeature

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureDeviceManagementTests {
  @Test
  func eraseAndDeleteButtonsOnlyPresentConfirmation() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", name: "Erase Target")
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let recorder = MainWindowPhase14CommandRecorder(
      result: MainWindowTestFixtures.makeCommandResult(
        id: "unexpected-destructive-command",
        arguments: ["simctl", "erase", device.id]
      )
    )
    let confirmationState = MainWindowFeature.DeviceDestructiveConfirmationState(
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.eraseDevice = { id in
        await recorder.eraseDevice(id: id)
      }
      $0.coreSimulatorService.deleteDevice = { id in
        await recorder.deleteDevice(id: id)
      }
    }

    await store.send(.workspace(.deviceDetail(.eraseButtonTapped(device.id)))) {
      $0.lifecycleSheet = .erase(confirmationState)
    }
    #expect(await recorder.eraseCalls().isEmpty)
    #expect(await recorder.deleteCalls().isEmpty)

    await store.send(.lifecycleSheetDismissed) {
      $0.lifecycleSheet = nil
    }

    await store.send(.workspace(.deviceDetail(.deleteButtonTapped(device.id)))) {
      $0.lifecycleSheet = .delete(confirmationState)
    }
    #expect(await recorder.eraseCalls().isEmpty)
    #expect(await recorder.deleteCalls().isEmpty)
  }

  @Test
  func eraseDeviceRecordsCommandResultAndRefreshesSnapshot() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", name: "Erase Target")
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let eraseResult = MainWindowTestFixtures.makeCommandResult(
      id: "erase-device",
      arguments: ["simctl", "erase", device.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let confirmationState = MainWindowFeature.DeviceDestructiveConfirmationState(
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid
    )
    let deviceCommandState = DeviceCommandState(command: .erase, deviceID: device.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.eraseDevice = { _ in
        eraseResult
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.eraseDeviceConfirmed(confirmationState)) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, eraseResult)) {
      $0.workspace.appendCommandResult(eraseResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: nil
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        commandResults: [
          eraseResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func deleteDeviceClearsSelectionWhenDeviceDisappears() async {
    let deletedDevice = MainWindowTestFixtures.makeDevice(id: "DELETED", name: "Delete Target")
    let remainingDevice = MainWindowTestFixtures.makeDevice(id: "REMAINING")
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        deletedDevice,
        remainingDevice
      ]
    )
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [remainingDevice])
    let deleteResult = MainWindowTestFixtures.makeCommandResult(
      id: "delete-device",
      arguments: ["simctl", "delete", deletedDevice.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let confirmationState = MainWindowFeature.DeviceDestructiveConfirmationState(
      deviceID: deletedDevice.id,
      deviceName: deletedDevice.name,
      deviceUDID: deletedDevice.udid
    )
    let deviceCommandState = DeviceCommandState(command: .delete, deviceID: deletedDevice.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: deletedDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.deleteDevice = { _ in
        deleteResult
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.deleteDeviceConfirmed(confirmationState)) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, deleteResult)) {
      $0.workspace.appendCommandResult(deleteResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: nil
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          deleteResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func pairDevicesUsesWatchThenPhoneOrderAndRefreshesSnapshot() async {
    let phone = MainWindowTestFixtures.makeDevice(id: "PHONE", name: "Phone")
    let watch = MainWindowTestFixtures.makeDevice(
      id: "WATCH",
      name: "Watch",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      runtimes: [
        MainWindowTestFixtures.runtime,
        MainWindowTestFixtures.watchRuntime
      ],
      deviceTypes: [
        MainWindowTestFixtures.deviceType,
        MainWindowTestFixtures.watchDeviceType
      ],
      devices: [
        phone,
        watch
      ]
    )
    let pairResult = MainWindowTestFixtures.makeCommandResult(
      id: "pair-devices",
      arguments: ["simctl", "pair", watch.id, phone.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let formState = MainWindowFeature.PairDevicesFormState(
      phoneDeviceID: phone.id,
      watchDeviceID: watch.id
    )
    let deviceCommandState = DeviceCommandState(command: .pair)
    let recorder = MainWindowPhase14CommandRecorder(result: pairResult)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: phone.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.pairDevices = { watchDeviceID, phoneDeviceID in
        await recorder.pairDevices(
          watchDeviceID: watchDeviceID,
          phoneDeviceID: phoneDeviceID
        )
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.pairDevicesSubmitted(formState)) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, pairResult)) {
      $0.workspace.appendCommandResult(pairResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: nil
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        commandResults: [
          pairResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.pairCalls() == [
      MainWindowPairDevicesCall(
        watchDeviceID: watch.id,
        phoneDeviceID: phone.id
      )
    ])
  }

  @Test
  func pairCandidatesExcludeAlreadyPairedWatches() async {
    let phone = MainWindowTestFixtures.makeDevice(id: "PHONE", name: "Phone")
    let pairedWatch = MainWindowTestFixtures.makeDevice(
      id: "PAIRED-WATCH",
      name: "Paired Watch",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let availableWatch = MainWindowTestFixtures.makeDevice(
      id: "AVAILABLE-WATCH",
      name: "Available Watch",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let pair = DevicePair(
      id: "PAIR-1",
      phoneDeviceID: phone.id,
      watchDeviceID: pairedWatch.id,
      state: .active
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      runtimes: [
        MainWindowTestFixtures.runtime,
        MainWindowTestFixtures.watchRuntime
      ],
      deviceTypes: [
        MainWindowTestFixtures.deviceType,
        MainWindowTestFixtures.watchDeviceType
      ],
      devices: [
        phone,
        pairedWatch,
        availableWatch
      ],
      pairs: [pair]
    )
    let state = MainWindowFeature.State(
      snapshot: snapshot,
      selectedDeviceID: phone.id
    )

    #expect(state.pairWatchCandidates.map(\.id) == [availableWatch.id])
    #expect(state.initialPairDevicesFormState?.watchDeviceID == availableWatch.id)
  }

  @Test
  func unpairDeviceUsesPairIDAndRefreshesSnapshot() async {
    let phone = MainWindowTestFixtures.makeDevice(id: "PHONE", name: "Phone")
    let watch = MainWindowTestFixtures.makeDevice(
      id: "WATCH",
      name: "Watch",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let pair = DevicePair(
      id: "PAIR-1",
      phoneDeviceID: phone.id,
      watchDeviceID: watch.id,
      state: .active
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(
      runtimes: [
        MainWindowTestFixtures.runtime,
        MainWindowTestFixtures.watchRuntime
      ],
      deviceTypes: [
        MainWindowTestFixtures.deviceType,
        MainWindowTestFixtures.watchDeviceType
      ],
      devices: [
        phone,
        watch
      ],
      pairs: [pair]
    )
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      runtimes: [
        MainWindowTestFixtures.runtime,
        MainWindowTestFixtures.watchRuntime
      ],
      deviceTypes: [
        MainWindowTestFixtures.deviceType,
        MainWindowTestFixtures.watchDeviceType
      ],
      devices: [
        phone,
        watch
      ]
    )
    let unpairResult = MainWindowTestFixtures.makeCommandResult(
      id: "unpair-device",
      arguments: ["simctl", "unpair", pair.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let confirmationState = MainWindowFeature.UnpairDeviceConfirmationState(
      pairID: pair.id,
      phoneName: phone.name,
      phoneUDID: phone.udid,
      watchName: watch.name,
      watchUDID: watch.udid
    )
    let deviceCommandState = DeviceCommandState(command: .unpair)
    let recorder = MainWindowPhase14CommandRecorder(result: unpairResult)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: phone.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.unpairDevice = { pairID in
        await recorder.unpairDevice(pairID: pairID)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.unpairDeviceConfirmed(confirmationState)) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, unpairResult)) {
      $0.workspace.appendCommandResult(unpairResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: nil
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          unpairResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.unpairCalls() == [pair.id])
  }

  @Test
  func duplicatePhase14CommandsAreIgnoredWhileRunning() async {
    let phone = MainWindowTestFixtures.makeDevice(id: "PHONE", name: "Phone")
    let availableWatch = MainWindowTestFixtures.makeDevice(
      id: "AVAILABLE-WATCH",
      name: "Available Watch",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let pairedWatch = MainWindowTestFixtures.makeDevice(
      id: "PAIRED-WATCH",
      name: "Paired Watch",
      runtimeID: MainWindowTestFixtures.watchRuntime.id,
      deviceTypeID: MainWindowTestFixtures.watchDeviceType.id,
      platform: .watchOS
    )
    let pair = DevicePair(
      id: "PAIR-1",
      phoneDeviceID: phone.id,
      watchDeviceID: pairedWatch.id,
      state: .active
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      runtimes: [
        MainWindowTestFixtures.runtime,
        MainWindowTestFixtures.watchRuntime
      ],
      deviceTypes: [
        MainWindowTestFixtures.deviceType,
        MainWindowTestFixtures.watchDeviceType
      ],
      devices: [
        phone,
        availableWatch,
        pairedWatch
      ],
      pairs: [pair]
    )
    let eraseResult = MainWindowTestFixtures.makeCommandResult(
      id: "erase-device",
      arguments: ["simctl", "erase", phone.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let recorder = MainWindowBlockingCommandRecorder(result: eraseResult)
    let confirmationState = MainWindowFeature.DeviceDestructiveConfirmationState(
      deviceID: phone.id,
      deviceName: phone.name,
      deviceUDID: phone.udid
    )
    let pairFormState = MainWindowFeature.PairDevicesFormState(
      phoneDeviceID: phone.id,
      watchDeviceID: availableWatch.id
    )
    let unpairConfirmationState = MainWindowFeature.UnpairDeviceConfirmationState(
      pairID: pair.id,
      phoneName: phone.name,
      phoneUDID: phone.udid,
      watchName: pairedWatch.name,
      watchUDID: pairedWatch.udid
    )
    let deviceCommandState = DeviceCommandState(command: .erase, deviceID: phone.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: phone.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.eraseDevice = { _ in
        await recorder.run()
      }
      $0.coreSimulatorService.deleteDevice = { _ in
        await recorder.run()
      }
      $0.coreSimulatorService.pairDevices = { _, _ in
        await recorder.run()
      }
      $0.coreSimulatorService.unpairDevice = { _ in
        await recorder.run()
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.eraseDeviceConfirmed(confirmationState)) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }
    await recorder.waitUntilCommandStarted()

    await store.send(.deleteDeviceConfirmed(confirmationState))
    await store.send(.pairDevicesSubmitted(pairFormState))
    await store.send(.unpairDeviceConfirmed(unpairConfirmationState))
    #expect(await recorder.calls() == 1)

    await recorder.releaseCommand()

    await store.receive(.deviceCommandResponse(deviceCommandState, eraseResult)) {
      $0.workspace.appendCommandResult(eraseResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: nil
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        commandResults: [
          eraseResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }
}

private struct MainWindowPairDevicesCall: Equatable {
  let watchDeviceID: String
  let phoneDeviceID: String
}

private actor MainWindowPhase14CommandRecorder {
  private let result: CommandResult
  private var recordedEraseCalls: [String] = []
  private var recordedDeleteCalls: [String] = []
  private var recordedPairCalls: [MainWindowPairDevicesCall] = []
  private var recordedUnpairCalls: [String] = []

  init(result: CommandResult) {
    self.result = result
  }

  func eraseDevice(id: String) -> CommandResult {
    recordedEraseCalls.append(id)
    return result
  }

  func deleteDevice(id: String) -> CommandResult {
    recordedDeleteCalls.append(id)
    return result
  }

  func pairDevices(watchDeviceID: String, phoneDeviceID: String) -> CommandResult {
    recordedPairCalls.append(
      MainWindowPairDevicesCall(
        watchDeviceID: watchDeviceID,
        phoneDeviceID: phoneDeviceID
      )
    )
    return result
  }

  func unpairDevice(pairID: String) -> CommandResult {
    recordedUnpairCalls.append(pairID)
    return result
  }

  func eraseCalls() -> [String] {
    recordedEraseCalls
  }

  func deleteCalls() -> [String] {
    recordedDeleteCalls
  }

  func pairCalls() -> [MainWindowPairDevicesCall] {
    recordedPairCalls
  }

  func unpairCalls() -> [String] {
    recordedUnpairCalls
  }
}
