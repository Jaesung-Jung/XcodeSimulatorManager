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

  @Test
  func launchAppOnShutdownDeviceBootsThenLaunchesAndRefreshesSnapshot() async {
    let shutdownDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .shutdown
    )
    let bootedDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .booted
    )
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: shutdownDevice.id,
      bundleID: "com.example.app"
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [shutdownDevice],
      installedAppsByDeviceID: [shutdownDevice.id: [app]]
    )
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [bootedDevice],
      installedAppsByDeviceID: [bootedDevice.id: [app]]
    )
    let bootResult = MainWindowTestFixtures.makeCommandResult(
      id: "bootstatus-device",
      arguments: ["simctl", "bootstatus", shutdownDevice.id, "-b"]
    )
    let launchResult = MainWindowTestFixtures.makeCommandResult(
      id: "launch-app",
      arguments: ["simctl", "launch", shutdownDevice.id, app.bundleID]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let appCommandState = AppCommandState(
      command: .launch,
      sourceDeviceID: shutdownDevice.id,
      appID: app.id
    )
    let recorder = MainWindowAppCommandRecorder(
      bootResult: bootResult,
      launchResult: launchResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: shutdownDevice.id,
        selectedAppID: app.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDeviceIfNeeded = { id in
        await recorder.bootDeviceIfNeeded(id: id)
      }
      $0.coreSimulatorService.launchApp = { deviceID, bundleID in
        await recorder.launchApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.launchButtonTapped(app.id))))) {
      $0.workspace.setAppCommandState(appCommandState)
    }

    await store.receive(
      .appCommandCommandsCompleted(
        appCommandState,
        [bootResult, launchResult],
        preferredSelectedDeviceID: shutdownDevice.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.workspace.appendCommandResult(bootResult)
      $0.workspace.appendCommandResult(launchResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .appCommandRefreshResponse(
        appCommandState,
        refreshResult,
        preferredSelectedDeviceID: shutdownDevice.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          bootResult,
          launchResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: shutdownDevice.id,
        preferredSelectedAppID: app.id
      )
      $0.workspace.setAppCommandState(nil)
    }

    #expect(await recorder.bootCalls() == [shutdownDevice.id])
    #expect(await recorder.launchCalls() == [
      MainWindowAppCall(deviceID: shutdownDevice.id, bundleID: app.bundleID)
    ])
  }

  @Test
  func failedLaunchBootSkipsLaunchAndStillRefreshes() async {
    let shutdownDevice = MainWindowTestFixtures.makeDevice(
      id: MainWindowTestFixtures.device.id,
      state: .shutdown
    )
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: shutdownDevice.id,
      bundleID: "com.example.app"
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [shutdownDevice],
      installedAppsByDeviceID: [shutdownDevice.id: [app]]
    )
    let failedBootResult = MainWindowTestFixtures.makeCommandResult(
      id: "failed-bootstatus-device",
      arguments: ["simctl", "bootstatus", shutdownDevice.id, "-b"],
      stderr: "Unable to boot device.",
      exitCode: 65
    )
    let launchResult = MainWindowTestFixtures.makeCommandResult(
      id: "unexpected-launch",
      arguments: ["simctl", "launch", shutdownDevice.id, app.bundleID]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let appCommandState = AppCommandState(
      command: .launch,
      sourceDeviceID: shutdownDevice.id,
      appID: app.id
    )
    let recorder = MainWindowAppCommandRecorder(
      bootResult: failedBootResult,
      launchResult: launchResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: shutdownDevice.id,
        selectedAppID: app.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDeviceIfNeeded = { id in
        await recorder.bootDeviceIfNeeded(id: id)
      }
      $0.coreSimulatorService.launchApp = { deviceID, bundleID in
        await recorder.launchApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.launchButtonTapped(app.id))))) {
      $0.workspace.setAppCommandState(appCommandState)
    }

    await store.receive(
      .appCommandCommandsCompleted(
        appCommandState,
        [failedBootResult],
        preferredSelectedDeviceID: shutdownDevice.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.workspace.appendCommandResult(failedBootResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .appCommandRefreshResponse(
        appCommandState,
        refreshResult,
        preferredSelectedDeviceID: shutdownDevice.id,
        preferredSelectedAppID: app.id
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
        ],
        preferredSelectedDeviceID: shutdownDevice.id,
        preferredSelectedAppID: app.id
      )
      $0.workspace.setAppCommandState(nil)
    }

    #expect(await recorder.launchCalls().isEmpty)
  }

  @Test
  func uninstallAppRequiresConfirmationThenRefreshesInstalledApps() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app"
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [:]
    )
    let uninstallResult = MainWindowTestFixtures.makeCommandResult(
      id: "uninstall-app",
      arguments: ["simctl", "uninstall", device.id, app.bundleID]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let confirmationState = MainWindowFeature.AppDestructiveConfirmationState(
      appID: app.id,
      appName: app.displayName,
      bundleID: app.bundleID,
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid,
      dataContainerPath: nil
    )
    let appCommandState = AppCommandState(
      command: .uninstall,
      sourceDeviceID: device.id,
      appID: app.id
    )
    let recorder = MainWindowAppCommandRecorder(uninstallResult: uninstallResult)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: device.id,
        selectedAppID: app.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.uninstallApp = { deviceID, bundleID in
        await recorder.uninstallApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.uninstallButtonTapped(app.id))))) {
      $0.lifecycleSheet = .uninstallApp(confirmationState)
    }
    #expect(await recorder.uninstallCalls().isEmpty)

    await store.send(.uninstallAppConfirmed(confirmationState)) {
      $0.lifecycleSheet = nil
      $0.workspace.setAppCommandState(appCommandState)
    }

    await store.receive(
      .appCommandCommandsCompleted(
        appCommandState,
        [uninstallResult],
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: nil
      )
    ) {
      $0.workspace.appendCommandResult(uninstallResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .appCommandRefreshResponse(
        appCommandState,
        refreshResult,
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: nil
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          uninstallResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: nil
      )
      $0.workspace.setAppCommandState(nil)
    }
  }

  @Test
  func resetSandboxRequiresConfirmationAndRefreshes() async {
    let dataContainer = URL(fileURLWithPath: "/tmp/AppData")
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .shutdown)
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app",
      dataContainer: dataContainer
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let resetResult = MainWindowTestFixtures.makeCommandResult(
      id: "reset-sandbox",
      executable: "SimControl",
      arguments: ["reset-sandbox", dataContainer.path],
      stdout: "Removed 2 sandbox item(s)."
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let confirmationState = MainWindowFeature.AppDestructiveConfirmationState(
      appID: app.id,
      appName: app.displayName,
      bundleID: app.bundleID,
      deviceID: device.id,
      deviceName: device.name,
      deviceUDID: device.udid,
      dataContainerPath: dataContainer.path
    )
    let appCommandState = AppCommandState(
      command: .resetSandbox,
      sourceDeviceID: device.id,
      appID: app.id
    )
    let recorder = MainWindowCommandRecorder(result: resetResult)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id,
        selectedAppID: app.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.appSandboxReset.resetSandbox = { _ in
        await recorder.run()
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.resetSandboxButtonTapped(app.id))))) {
      $0.lifecycleSheet = .resetAppSandbox(confirmationState)
    }
    #expect(await recorder.calls() == 0)

    await store.send(.resetAppSandboxConfirmed(confirmationState)) {
      $0.lifecycleSheet = nil
      $0.workspace.setAppCommandState(appCommandState)
    }

    await store.receive(
      .appCommandCommandsCompleted(
        appCommandState,
        [resetResult],
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.workspace.appendCommandResult(resetResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .appCommandRefreshResponse(
        appCommandState,
        refreshResult,
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        commandResults: [
          resetResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
      $0.workspace.setAppCommandState(nil)
    }
  }

  @Test
  func installAppOnShutdownTargetBootsInstallsLaunchesAndSelectsTargetApp() async {
    let appBundlePath = URL(fileURLWithPath: "/tmp/Example.app")
    let sourceDevice = MainWindowTestFixtures.makeDevice(id: "SOURCE", state: .booted)
    let targetDevice = MainWindowTestFixtures.makeDevice(id: "TARGET", state: .shutdown)
    let bootedTargetDevice = MainWindowTestFixtures.makeDevice(id: "TARGET", state: .booted)
    let sourceApp = MainWindowTestFixtures.makeInstalledApp(
      deviceID: sourceDevice.id,
      bundleID: "com.example.app",
      appBundlePath: appBundlePath
    )
    let targetApp = MainWindowTestFixtures.makeInstalledApp(
      deviceID: targetDevice.id,
      bundleID: sourceApp.bundleID,
      appBundlePath: appBundlePath
    )
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [sourceDevice, targetDevice],
      installedAppsByDeviceID: [sourceDevice.id: [sourceApp]]
    )
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [sourceDevice, bootedTargetDevice],
      installedAppsByDeviceID: [
        sourceDevice.id: [sourceApp],
        targetDevice.id: [targetApp]
      ]
    )
    let formState = MainWindowFeature.InstallAppTargetFormState(
      sourceAppID: sourceApp.id,
      sourceDeviceID: sourceDevice.id,
      appName: sourceApp.displayName,
      bundleID: sourceApp.bundleID,
      appBundlePath: appBundlePath,
      targetDeviceID: targetDevice.id,
      launchAfterInstall: true
    )
    let bootResult = MainWindowTestFixtures.makeCommandResult(
      id: "bootstatus-target",
      arguments: ["simctl", "bootstatus", targetDevice.id, "-b"]
    )
    let installResult = MainWindowTestFixtures.makeCommandResult(
      id: "install-app",
      arguments: ["simctl", "install", targetDevice.id, appBundlePath.path]
    )
    let launchResult = MainWindowTestFixtures.makeCommandResult(
      id: "launch-installed-app",
      arguments: ["simctl", "launch", targetDevice.id, sourceApp.bundleID]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let appCommandState = AppCommandState(
      command: .installOnSimulator,
      sourceDeviceID: sourceDevice.id,
      appID: sourceApp.id,
      targetDeviceID: targetDevice.id
    )
    let recorder = MainWindowAppCommandRecorder(
      bootResult: bootResult,
      launchResult: launchResult,
      installResult: installResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: sourceDevice.id,
        selectedAppID: sourceApp.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDeviceIfNeeded = { id in
        await recorder.bootDeviceIfNeeded(id: id)
      }
      $0.coreSimulatorService.installApp = { deviceID, appBundlePath in
        await recorder.installApp(deviceID: deviceID, appBundlePath: appBundlePath)
      }
      $0.coreSimulatorService.launchApp = { deviceID, bundleID in
        await recorder.launchApp(deviceID: deviceID, bundleID: bundleID)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.installAppOnSimulatorSubmitted(formState)) {
      $0.workspace.setAppCommandState(appCommandState)
    }

    await store.receive(
      .appCommandCommandsCompleted(
        appCommandState,
        [bootResult, installResult, launchResult],
        preferredSelectedDeviceID: targetDevice.id,
        preferredSelectedAppID: targetApp.id
      )
    ) {
      $0.workspace.appendCommandResult(bootResult)
      $0.workspace.appendCommandResult(installResult)
      $0.workspace.appendCommandResult(launchResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .appCommandRefreshResponse(
        appCommandState,
        refreshResult,
        preferredSelectedDeviceID: targetDevice.id,
        preferredSelectedAppID: targetApp.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        commandResults: [
          bootResult,
          installResult,
          launchResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: targetDevice.id,
        preferredSelectedAppID: targetApp.id
      )
      $0.workspace.setAppCommandState(nil)
    }

    #expect(await recorder.installCalls() == [
      MainWindowInstallAppCall(deviceID: targetDevice.id, appBundlePath: appBundlePath)
    ])
  }

  @Test
  func duplicateAppCommandsAreIgnoredWhileRunning() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app"
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let launchResult = MainWindowTestFixtures.makeCommandResult(
      id: "launch-app",
      arguments: ["simctl", "launch", device.id, app.bundleID]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    let recorder = MainWindowBlockingCommandRecorder(result: launchResult)
    let appCommandState = AppCommandState(
      command: .launch,
      sourceDeviceID: device.id,
      appID: app.id
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id,
        selectedAppID: app.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.launchApp = { _, _ in
        await recorder.run()
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.launchButtonTapped(app.id))))) {
      $0.workspace.setAppCommandState(appCommandState)
    }
    await recorder.waitUntilCommandStarted()

    await store.send(.workspace(.deviceDetail(.installedApps(.launchButtonTapped(app.id)))))
    #expect(await recorder.calls() == 1)

    await recorder.releaseCommand()

    await store.receive(
      .appCommandCommandsCompleted(
        appCommandState,
        [launchResult],
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.workspace.appendCommandResult(launchResult)
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .appCommandRefreshResponse(
        appCommandState,
        refreshResult,
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: snapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        snapshot,
        refreshState: .idle,
        commandResults: [
          launchResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
      $0.workspace.setAppCommandState(nil)
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

private struct MainWindowPairDevicesCall: Equatable {
  let watchDeviceID: String
  let phoneDeviceID: String
}

private struct MainWindowAppCall: Equatable {
  let deviceID: String
  let bundleID: String
}

private struct MainWindowInstallAppCall: Equatable {
  let deviceID: String
  let appBundlePath: URL
}

private actor MainWindowAppCommandRecorder {
  private let bootResult: CommandResult
  private let launchResult: CommandResult
  private let terminateResult: CommandResult
  private let uninstallResult: CommandResult
  private let installResult: CommandResult
  private var recordedBootCalls: [String] = []
  private var recordedLaunchCalls: [MainWindowAppCall] = []
  private var recordedTerminateCalls: [MainWindowAppCall] = []
  private var recordedUninstallCalls: [MainWindowAppCall] = []
  private var recordedInstallCalls: [MainWindowInstallAppCall] = []

  init(
    bootResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "bootstatus",
      arguments: ["simctl", "bootstatus", "DEVICE", "-b"]
    ),
    launchResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "launch-app",
      arguments: ["simctl", "launch", "DEVICE", "com.example.app"]
    ),
    terminateResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "terminate-app",
      arguments: ["simctl", "terminate", "DEVICE", "com.example.app"]
    ),
    uninstallResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "uninstall-app",
      arguments: ["simctl", "uninstall", "DEVICE", "com.example.app"]
    ),
    installResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "install-app",
      arguments: ["simctl", "install", "DEVICE", "/tmp/Example.app"]
    )
  ) {
    self.bootResult = bootResult
    self.launchResult = launchResult
    self.terminateResult = terminateResult
    self.uninstallResult = uninstallResult
    self.installResult = installResult
  }

  func bootDeviceIfNeeded(id: String) -> CommandResult {
    recordedBootCalls.append(id)
    return bootResult
  }

  func launchApp(deviceID: String, bundleID: String) -> CommandResult {
    recordedLaunchCalls.append(
      MainWindowAppCall(deviceID: deviceID, bundleID: bundleID)
    )
    return launchResult
  }

  func terminateApp(deviceID: String, bundleID: String) -> CommandResult {
    recordedTerminateCalls.append(
      MainWindowAppCall(deviceID: deviceID, bundleID: bundleID)
    )
    return terminateResult
  }

  func uninstallApp(deviceID: String, bundleID: String) -> CommandResult {
    recordedUninstallCalls.append(
      MainWindowAppCall(deviceID: deviceID, bundleID: bundleID)
    )
    return uninstallResult
  }

  func installApp(deviceID: String, appBundlePath: URL) -> CommandResult {
    recordedInstallCalls.append(
      MainWindowInstallAppCall(deviceID: deviceID, appBundlePath: appBundlePath)
    )
    return installResult
  }

  func bootCalls() -> [String] {
    recordedBootCalls
  }

  func launchCalls() -> [MainWindowAppCall] {
    recordedLaunchCalls
  }

  func terminateCalls() -> [MainWindowAppCall] {
    recordedTerminateCalls
  }

  func uninstallCalls() -> [MainWindowAppCall] {
    recordedUninstallCalls
  }

  func installCalls() -> [MainWindowInstallAppCall] {
    recordedInstallCalls
  }
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
