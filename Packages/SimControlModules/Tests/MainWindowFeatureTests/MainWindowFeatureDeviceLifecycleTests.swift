import ComposableArchitecture
import MainWindowFeatureSupport
import SidebarFeature
import Testing
import WorkspaceFeature

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureDeviceLifecycleTests {
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
}
