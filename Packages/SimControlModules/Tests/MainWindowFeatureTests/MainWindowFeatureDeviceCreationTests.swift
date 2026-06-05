import ComposableArchitecture
import MainWindowFeatureSupport
import SidebarFeature
import SimControlDomain
import Testing
import WorkspaceFeature

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureDeviceCreationTests {
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
        refreshState: .idle
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
        preferredSelectedDeviceID: createdDevice.id
      )
      $0.workspace.setDeviceCommandState(nil)
    }
  }
}

extension MainWindowFeatureDeviceCreationTests {
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
}
