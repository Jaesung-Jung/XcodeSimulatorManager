import ComposableArchitecture
import Foundation
import Testing

@testable import SimControl

@MainActor
struct MainWindowFeatureTests {
  @Test
  func taskRefreshesWhenSnapshotIsMissing() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    let result = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let expectedCommandResults = [
      MainWindowTestFixtures.xcodeCommandResult,
      MainWindowTestFixtures.listCommandResult
    ]

    let store = TestStore(initialState: MainWindowFeature.State()) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        result
      }
    }

    await store.send(.task) {
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(result)) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace = WorkspaceFeature.State(
        snapshot: snapshot,
        refreshState: .idle,
        commandResults: expectedCommandResults
      )
    }
  }

  @Test
  func manualRefreshUpdatesExistingSnapshot() async {
    let oldSnapshot = MainWindowTestFixtures.makeSnapshot()
    let newSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ]
    )
    let result = MainWindowTestFixtures.makeRefreshResult(snapshot: newSnapshot)
    let expectedCommandResults = [
      MainWindowTestFixtures.xcodeCommandResult,
      MainWindowTestFixtures.listCommandResult
    ]

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: oldSnapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        result
      }
    }

    await store.send(.refreshButtonTapped) {
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(result)) {
      $0.sidebar = SidebarFeature.State(snapshot: newSnapshot, refreshState: .idle)
      $0.workspace = WorkspaceFeature.State(
        snapshot: newSnapshot,
        refreshState: .idle,
        commandResults: expectedCommandResults
      )
    }
  }

  @Test
  func duplicateRefreshRequestsAreIgnoredWhileRefreshing() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    let result = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let recorder = MainWindowBlockingRefreshRecorder(result: result)
    let expectedCommandResults = [
      MainWindowTestFixtures.xcodeCommandResult,
      MainWindowTestFixtures.listCommandResult
    ]

    let store = TestStore(initialState: MainWindowFeature.State()) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        await recorder.refresh()
      }
    }

    await store.send(.refreshButtonTapped) {
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }
    await recorder.waitUntilRefreshStarted()

    await store.send(.refreshButtonTapped)
    #expect(await recorder.refreshCallCount() == 1)

    await recorder.releaseRefresh()

    await store.receive(.refreshResponse(result)) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace = WorkspaceFeature.State(
        snapshot: snapshot,
        refreshState: .idle,
        commandResults: expectedCommandResults
      )
    }
  }

  @Test
  func refreshFailurePreservesLastSuccessfulSnapshot() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    let failureResult = MainWindowTestFixtures.makeRefreshResult(
      snapshot: nil,
      xcodeCommandResult: MainWindowTestFixtures.failedXcodeCommandResult,
      listCommandResult: nil,
      diagnostic: "simctl list failed"
    )
    let initialState = MainWindowFeature.State(
      snapshot: snapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id
    )

    let store = TestStore(initialState: initialState) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        failureResult
      }
    }

    await store.send(.refreshButtonTapped) {
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(failureResult)) {
      let failedState = InventoryRefreshState.failed(diagnostic: "simctl list failed")
      $0.sidebar.refreshState = failedState
      $0.workspace.applyRefreshFailure(
        failedState,
        commandResults: [MainWindowTestFixtures.failedXcodeCommandResult]
      )
    }
  }

  @Test
  func refreshClearsMissingSelectedDeviceAndApp() async {
    let oldSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ],
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app]
      ]
    )
    let newSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [MainWindowTestFixtures.secondDevice]
    )
    let result = MainWindowTestFixtures.makeRefreshResult(snapshot: newSnapshot)
    let expectedCommandResults = [
      MainWindowTestFixtures.xcodeCommandResult,
      MainWindowTestFixtures.listCommandResult
    ]
    let initialState = MainWindowFeature.State(
      snapshot: oldSnapshot,
      selectedDeviceID: MainWindowTestFixtures.device.id,
      selectedAppID: MainWindowTestFixtures.app.id,
      installedAppsAvailability: .loaded
    )

    let store = TestStore(initialState: initialState) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        result
      }
    }

    await store.send(.refreshButtonTapped) {
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(result)) {
      $0.sidebar = SidebarFeature.State(snapshot: newSnapshot, refreshState: .idle)
      $0.workspace = WorkspaceFeature.State(
        snapshot: newSnapshot,
        refreshState: .idle,
        commandResults: expectedCommandResults,
        installedAppsAvailability: .loaded
      )
    }
  }

  @Test
  func menuBarPresentationRefreshesWhenSnapshotIsMissing() async {
    let now = Date(timeIntervalSince1970: 2_000)
    let snapshot = MainWindowTestFixtures.makeSnapshot(generatedAt: now)
    let result = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let expectedCommandResults = [
      MainWindowTestFixtures.xcodeCommandResult,
      MainWindowTestFixtures.listCommandResult
    ]

    let store = TestStore(initialState: MainWindowFeature.State()) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        result
      }
    }

    await store.send(.menuBarPresented(at: now)) {
      $0.lastMenuBarAutoRefreshAttemptAt = now
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(result)) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace = WorkspaceFeature.State(
        snapshot: snapshot,
        refreshState: .idle,
        commandResults: expectedCommandResults
      )
    }
  }

  @Test
  func menuBarPresentationDoesNotRefreshFreshSnapshot() async {
    let now = Date(timeIntervalSince1970: 2_000)
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      generatedAt: now.addingTimeInterval(-30)
    )
    let recorder = MainWindowRefreshRecorder(
      result: MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: snapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        await recorder.refresh()
      }
    }

    await store.send(.menuBarPresented(at: now))

    #expect(await recorder.refreshCallCount() == 0)
  }

  @Test
  func menuBarPresentationRefreshesStaleSnapshot() async {
    let now = Date(timeIntervalSince1970: 2_000)
    let oldSnapshot = MainWindowTestFixtures.makeSnapshot(
      generatedAt: now.addingTimeInterval(-61)
    )
    let newSnapshot = MainWindowTestFixtures.makeSnapshot(generatedAt: now)
    let result = MainWindowTestFixtures.makeRefreshResult(snapshot: newSnapshot)
    let expectedCommandResults = [
      MainWindowTestFixtures.xcodeCommandResult,
      MainWindowTestFixtures.listCommandResult
    ]

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: oldSnapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        result
      }
    }

    await store.send(.menuBarPresented(at: now)) {
      $0.lastMenuBarAutoRefreshAttemptAt = now
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(result)) {
      $0.sidebar = SidebarFeature.State(snapshot: newSnapshot, refreshState: .idle)
      $0.workspace = WorkspaceFeature.State(
        snapshot: newSnapshot,
        refreshState: .idle,
        commandResults: expectedCommandResults
      )
    }
  }

  @Test
  func menuBarAutoRefreshFailureDoesNotRepeatWithinInterval() async {
    let now = Date(timeIntervalSince1970: 2_000)
    let failureResult = MainWindowTestFixtures.makeRefreshResult(
      snapshot: nil,
      xcodeCommandResult: MainWindowTestFixtures.failedXcodeCommandResult,
      listCommandResult: nil,
      diagnostic: "simctl list failed"
    )
    let recorder = MainWindowRefreshRecorder(result: failureResult)

    let store = TestStore(initialState: MainWindowFeature.State()) {
      MainWindowFeature()
    } withDependencies: {
      $0.simulatorRepository.refresh = {
        await recorder.refresh()
      }
    }

    await store.send(.menuBarPresented(at: now)) {
      $0.lastMenuBarAutoRefreshAttemptAt = now
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(.refreshResponse(failureResult)) {
      let failedState = InventoryRefreshState.failed(diagnostic: "simctl list failed")
      $0.sidebar.refreshState = failedState
      $0.workspace.applyRefreshFailure(
        failedState,
        commandResults: [MainWindowTestFixtures.failedXcodeCommandResult]
      )
    }

    await store.send(.menuBarPresented(at: now.addingTimeInterval(30)))

    #expect(await recorder.refreshCallCount() == 1)
  }

  @Test
  func bootDeviceRecordsCommandResultAndRefreshesSnapshot() async {
    let shutdownDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .shutdown
    )
    let bootedDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .booted
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [shutdownDevice])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [bootedDevice])
    let previousResult = MainWindowTestFixtures.makeCommandResult(
      id: "previous-list",
      arguments: ["simctl", "list", "-j"]
    )
    let bootResult = MainWindowTestFixtures.makeCommandResult(
      id: "boot-device",
      arguments: ["simctl", "boot", shutdownDevice.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let deviceCommandState = DeviceCommandState(command: .boot, deviceID: shutdownDevice.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: shutdownDevice.id,
        lastCommandResults: [previousResult]
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDevice = { _ in
        bootResult
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.bootButtonTapped(shutdownDevice.id)))) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, bootResult)) {
      $0.workspace.appendCommandResult(bootResult)
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
          previousResult,
          bootResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func shutdownDeviceRecordsCommandResultAndRefreshesSnapshot() async {
    let bootedDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .booted
    )
    let shutdownDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .shutdown
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [bootedDevice])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [shutdownDevice])
    let shutdownResult = MainWindowTestFixtures.makeCommandResult(
      id: "shutdown-device",
      arguments: ["simctl", "shutdown", bootedDevice.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let deviceCommandState = DeviceCommandState(command: .shutdown, deviceID: bootedDevice.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: bootedDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.shutdownDevice = { _ in
        shutdownResult
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.shutdownButtonTapped(bootedDevice.id)))) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, shutdownResult)) {
      $0.workspace.appendCommandResult(shutdownResult)
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
          shutdownResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func invalidDeviceCommandsDoNotCallService() async {
    let bootedDevice = MainWindowTestFixtures.makeDevice(id: "BOOTED", state: .booted)
    let shutdownDevice = MainWindowTestFixtures.makeDevice(id: "SHUTDOWN", state: .shutdown)
    let unavailableDevice = MainWindowTestFixtures.makeDevice(
      id: "UNAVAILABLE",
      state: .shutdown,
      isAvailable: false
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        bootedDevice,
        shutdownDevice,
        unavailableDevice
      ]
    )
    let recorder = MainWindowCommandRecorder(
      result: MainWindowTestFixtures.makeCommandResult(
        id: "unexpected-action",
        arguments: ["simctl", "boot", "DEVICE"]
      )
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: snapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDevice = { _ in
        await recorder.run()
      }
      $0.coreSimulatorService.shutdownDevice = { _ in
        await recorder.run()
      }
    }

    await store.send(.workspace(.deviceDetail(.bootButtonTapped(bootedDevice.id))))
    await store.send(.workspace(.deviceDetail(.shutdownButtonTapped(shutdownDevice.id))))
    await store.send(.workspace(.deviceDetail(.bootButtonTapped(unavailableDevice.id))))

    #expect(await recorder.calls() == 0)
  }

  @Test
  func duplicateDeviceCommandRequestsAreIgnoredWhileRunning() async {
    let shutdownDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .shutdown
    )
    let bootedDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .booted
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [shutdownDevice])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [bootedDevice])
    let bootResult = MainWindowTestFixtures.makeCommandResult(
      id: "boot-device",
      arguments: ["simctl", "boot", shutdownDevice.id]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let deviceCommandState = DeviceCommandState(command: .boot, deviceID: shutdownDevice.id)
    let recorder = MainWindowBlockingCommandRecorder(result: bootResult)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: shutdownDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDevice = { _ in
        await recorder.run()
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.bootButtonTapped(shutdownDevice.id)))) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }
    await recorder.waitUntilCommandStarted()

    await store.send(.workspace(.deviceDetail(.bootButtonTapped(shutdownDevice.id))))
    #expect(await recorder.calls() == 1)

    await recorder.releaseCommand()

    await store.receive(.deviceCommandResponse(deviceCommandState, bootResult)) {
      $0.workspace.appendCommandResult(bootResult)
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
          bootResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func failedDeviceCommandResultSurvivesFollowUpRefresh() async {
    let shutdownDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .shutdown
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [shutdownDevice])
    let failedBootResult = MainWindowTestFixtures.makeCommandResult(
      id: "failed-boot-device",
      arguments: ["simctl", "boot", shutdownDevice.id],
      stderr: "Unable to boot device.",
      exitCode: 65
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let deviceCommandState = DeviceCommandState(command: .boot, deviceID: shutdownDevice.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: shutdownDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDevice = { _ in
        failedBootResult
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.bootButtonTapped(shutdownDevice.id)))) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, failedBootResult)) {
      $0.workspace.appendCommandResult(failedBootResult)
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
          failedBootResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func createDeviceUsesDeviceTypeNameAndSelectsCreatedDevice() async {
    let existingDevice = MainWindowTestFixtures.makeDevice(id: "EXISTING")
    let createdDevice = MainWindowTestFixtures.makeDevice(
      id: "CREATED",
      name: MainWindowTestFixtures.deviceType.name
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [existingDevice])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        existingDevice,
        createdDevice
      ]
    )
    let createResult = MainWindowTestFixtures.makeCommandResult(
      id: "create-device",
      arguments: [
        "simctl",
        "create",
        MainWindowTestFixtures.deviceType.name,
        MainWindowTestFixtures.deviceType.id,
        MainWindowTestFixtures.runtime.id
      ],
      stdout: "\(createdDevice.id)\n"
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let deviceCommandState = DeviceCommandState(command: .create)
    let recorder = MainWindowDeviceLifecycleCommandRecorder(
      createResult: createResult,
      cloneResult: createResult,
      renameResult: createResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: existingDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.createDevice = { name, deviceTypeID, runtimeID in
        await recorder.createDevice(
          name: name,
          deviceTypeID: deviceTypeID,
          runtimeID: runtimeID
        )
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(
      .createDeviceSubmitted(
        MainWindowFeature.CreateDeviceFormState(
          name: "   ",
          runtimeID: MainWindowTestFixtures.runtime.id,
          deviceTypeID: MainWindowTestFixtures.deviceType.id
        )
      )
    ) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, createResult)) {
      $0.workspace.appendCommandResult(createResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: createdDevice.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          createResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: createdDevice.id
      )
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.createCalls() == [
      MainWindowCreateDeviceCall(
        name: MainWindowTestFixtures.deviceType.name,
        deviceTypeID: MainWindowTestFixtures.deviceType.id,
        runtimeID: MainWindowTestFixtures.runtime.id
      )
    ])
  }

  @Test
  func cloneDeviceSelectsClonedDevice() async {
    let sourceDevice = MainWindowTestFixtures.makeDevice(id: "SOURCE", name: "Source")
    let clonedDevice = MainWindowTestFixtures.makeDevice(id: "CLONED", name: "Source Copy")
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [sourceDevice])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        sourceDevice,
        clonedDevice
      ]
    )
    let cloneResult = MainWindowTestFixtures.makeCommandResult(
      id: "clone-device",
      arguments: ["simctl", "clone", sourceDevice.id, clonedDevice.name],
      stdout: "\(clonedDevice.id)\n"
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let deviceCommandState = DeviceCommandState(command: .clone, deviceID: sourceDevice.id)
    let recorder = MainWindowDeviceLifecycleCommandRecorder(
      createResult: cloneResult,
      cloneResult: cloneResult,
      renameResult: cloneResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: sourceDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.cloneDevice = { id, name in
        await recorder.cloneDevice(id: id, name: name)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(
      .cloneDeviceSubmitted(
        MainWindowFeature.CloneDeviceFormState(
          sourceDeviceID: sourceDevice.id,
          sourceName: sourceDevice.name,
          name: clonedDevice.name
        )
      )
    ) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, cloneResult)) {
      $0.workspace.appendCommandResult(cloneResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: clonedDevice.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          cloneResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: clonedDevice.id
      )
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.cloneCalls() == [
      MainWindowNamedDeviceCall(id: sourceDevice.id, name: clonedDevice.name)
    ])
  }

  @Test
  func renameDeviceKeepsSelectionAndRefreshesName() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", name: "Original")
    let renamedDevice = MainWindowTestFixtures.makeDevice(id: device.id, name: "Renamed")
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [renamedDevice])
    let renameResult = MainWindowTestFixtures.makeCommandResult(
      id: "rename-device",
      arguments: ["simctl", "rename", device.id, renamedDevice.name]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let deviceCommandState = DeviceCommandState(command: .rename, deviceID: device.id)
    let recorder = MainWindowDeviceLifecycleCommandRecorder(
      createResult: renameResult,
      cloneResult: renameResult,
      renameResult: renameResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.renameDevice = { id, name in
        await recorder.renameDevice(id: id, name: name)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(
      .renameDeviceSubmitted(
        MainWindowFeature.RenameDeviceFormState(
          deviceID: device.id,
          currentName: device.name,
          name: renamedDevice.name
        )
      )
    ) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }

    await store.receive(.deviceCommandResponse(deviceCommandState, renameResult)) {
      $0.workspace.appendCommandResult(renameResult)
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
          renameResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ]
      )
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.renameCalls() == [
      MainWindowNamedDeviceCall(id: device.id, name: renamedDevice.name)
    ])
  }

  @Test
  func invalidCreateCloneAndRenameCommandsDoNotCallService() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", name: "Device")
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "unexpected-lifecycle-command",
      arguments: ["simctl", "create", "Unexpected"]
    )
    let recorder = MainWindowDeviceLifecycleCommandRecorder(
      createResult: commandResult,
      cloneResult: commandResult,
      renameResult: commandResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.createDevice = { name, deviceTypeID, runtimeID in
        await recorder.createDevice(
          name: name,
          deviceTypeID: deviceTypeID,
          runtimeID: runtimeID
        )
      }
      $0.coreSimulatorService.cloneDevice = { id, name in
        await recorder.cloneDevice(id: id, name: name)
      }
      $0.coreSimulatorService.renameDevice = { id, name in
        await recorder.renameDevice(id: id, name: name)
      }
    }

    await store.send(
      .createDeviceSubmitted(
        MainWindowFeature.CreateDeviceFormState(
          name: "Device",
          runtimeID: "missing-runtime",
          deviceTypeID: MainWindowTestFixtures.deviceType.id
        )
      )
    )
    await store.send(
      .cloneDeviceSubmitted(
        MainWindowFeature.CloneDeviceFormState(
          sourceDeviceID: device.id,
          sourceName: device.name,
          name: " "
        )
      )
    )
    await store.send(
      .renameDeviceSubmitted(
        MainWindowFeature.RenameDeviceFormState(
          deviceID: device.id,
          currentName: device.name,
          name: device.name
        )
      )
    )

    #expect(await recorder.createCalls().isEmpty)
    #expect(await recorder.cloneCalls().isEmpty)
    #expect(await recorder.renameCalls().isEmpty)
  }

  @Test
  func duplicateCreateRequestsAreIgnoredWhileRunning() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    let createdDevice = MainWindowTestFixtures.makeDevice(id: "CREATED")
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        createdDevice
      ]
    )
    let createResult = MainWindowTestFixtures.makeCommandResult(
      id: "create-device",
      arguments: [
        "simctl",
        "create",
        MainWindowTestFixtures.deviceType.name,
        MainWindowTestFixtures.deviceType.id,
        MainWindowTestFixtures.runtime.id
      ],
      stdout: "\(createdDevice.id)\n"
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let recorder = MainWindowBlockingCommandRecorder(result: createResult)
    let deviceCommandState = DeviceCommandState(command: .create)
    let formState = MainWindowFeature.CreateDeviceFormState(
      runtimeID: MainWindowTestFixtures.runtime.id,
      deviceTypeID: MainWindowTestFixtures.deviceType.id
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: snapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.createDevice = { _, _, _ in
        await recorder.run()
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.createDeviceSubmitted(formState)) {
      $0.workspace.setDeviceCommandState(deviceCommandState)
    }
    await recorder.waitUntilCommandStarted()

    await store.send(.createDeviceSubmitted(formState))
    #expect(await recorder.calls() == 1)

    await recorder.releaseCommand()

    await store.receive(.deviceCommandResponse(deviceCommandState, createResult)) {
      $0.workspace.appendCommandResult(createResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .deviceCommandRefreshResponse(
        deviceCommandState,
        refreshResult,
        preferredSelectedDeviceID: createdDevice.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          createResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: createdDevice.id
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }

  @Test
  func openSimulatorAppRecordsCommandResult() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-simulator",
      executable: "open",
      arguments: ["-a", "Simulator"],
      exitCode: 1
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: snapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.openSimulatorApp = {
        commandResult
      }
    }

    await store.send(.openSimulatorAppButtonTapped) {
      $0.workspace.setOpeningSimulatorApp(true)
    }

    await store.receive(.openSimulatorAppResponse(commandResult)) {
      $0.workspace.appendCommandResult(commandResult)
      $0.workspace.setOpeningSimulatorApp(false)
    }
  }

  @Test
  func duplicateOpenSimulatorAppRequestsAreIgnoredWhileRunning() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot()
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-simulator",
      executable: "open",
      arguments: ["-a", "Simulator"]
    )
    let recorder = MainWindowBlockingCommandRecorder(result: commandResult)

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: snapshot)
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.openSimulatorApp = {
        await recorder.run()
      }
    }

    await store.send(.openSimulatorAppButtonTapped) {
      $0.workspace.setOpeningSimulatorApp(true)
    }
    await recorder.waitUntilCommandStarted()

    await store.send(.openSimulatorAppButtonTapped)
    #expect(await recorder.calls() == 1)

    await recorder.releaseCommand()

    await store.receive(.openSimulatorAppResponse(commandResult)) {
      $0.workspace.appendCommandResult(commandResult)
      $0.workspace.setOpeningSimulatorApp(false)
    }
  }
}

private struct MainWindowCreateDeviceCall: Equatable {
  let name: String
  let deviceTypeID: String
  let runtimeID: String
}

private struct MainWindowNamedDeviceCall: Equatable {
  let id: String
  let name: String
}

private actor MainWindowDeviceLifecycleCommandRecorder {
  private let createResult: CommandResult
  private let cloneResult: CommandResult
  private let renameResult: CommandResult
  private var recordedCreateCalls: [MainWindowCreateDeviceCall] = []
  private var recordedCloneCalls: [MainWindowNamedDeviceCall] = []
  private var recordedRenameCalls: [MainWindowNamedDeviceCall] = []

  init(
    createResult: CommandResult,
    cloneResult: CommandResult,
    renameResult: CommandResult
  ) {
    self.createResult = createResult
    self.cloneResult = cloneResult
    self.renameResult = renameResult
  }

  func createDevice(
    name: String,
    deviceTypeID: String,
    runtimeID: String
  ) -> CommandResult {
    recordedCreateCalls.append(
      MainWindowCreateDeviceCall(
        name: name,
        deviceTypeID: deviceTypeID,
        runtimeID: runtimeID
      )
    )
    return createResult
  }

  func cloneDevice(id: String, name: String) -> CommandResult {
    recordedCloneCalls.append(MainWindowNamedDeviceCall(id: id, name: name))
    return cloneResult
  }

  func renameDevice(id: String, name: String) -> CommandResult {
    recordedRenameCalls.append(MainWindowNamedDeviceCall(id: id, name: name))
    return renameResult
  }

  func createCalls() -> [MainWindowCreateDeviceCall] {
    recordedCreateCalls
  }

  func cloneCalls() -> [MainWindowNamedDeviceCall] {
    recordedCloneCalls
  }

  func renameCalls() -> [MainWindowNamedDeviceCall] {
    recordedRenameCalls
  }
}
