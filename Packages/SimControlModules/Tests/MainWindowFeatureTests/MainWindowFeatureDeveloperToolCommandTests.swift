import ComposableArchitecture
import DeveloperToolsFeature
import MainWindowFeatureSupport
import SidebarFeature
import Testing

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureDeveloperToolCommandTests {
  @Test
  func openDeepLinkCompletesWithoutRefreshing() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let openResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-url",
      arguments: ["simctl", "openurl", device.id, "myapp://home"]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: openResult,
      remoteNotificationResult: openResult,
      privacyResult: openResult,
      setLocationResult: openResult,
      clearLocationResult: openResult
    )
    let refreshRecorder = MainWindowRefreshRecorder(
      result: MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    )
    let commandState = DeviceCommandState(command: .openURL, deviceID: device.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.openURL = { deviceID, urlString in
        await recorder.openURL(deviceID: deviceID, urlString: urlString)
      }
      $0.simulatorRepository.refresh = {
        await refreshRecorder.refresh()
      }
    }

    await store.send(
      .workspace(.deviceDetail(.developerTools(.deepLinkURLChanged("myapp://home"))))
    ) {
      $0.workspace.deviceDetail.developerTools.deepLinkURLString = "myapp://home"
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.openDeepLinkButtonTapped)))) {
      $0.workspace.deviceDetail.developerTools.recentDeepLinkURLs = ["myapp://home"]
      $0.workspace.setDeviceCommandState(commandState)
    }

    await store.receive(
      .developerToolCommandResults(
        commandState,
        [openResult],
        refreshAfterward: false
      )
    ) {
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.openURLCalls() == [
      MainWindowOpenURLCall(deviceID: device.id, urlString: "myapp://home")
    ])
    #expect(await refreshRecorder.refreshCallCount() == 0)
  }

  @Test
  func developerToolOnShutdownDeviceBootsThenRefreshesSnapshot() async {
    let shutdownDevice = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .shutdown)
    let bootedDevice = MainWindowTestFixtures.makeDevice(id: shutdownDevice.id, state: .booted)
    let initialSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [shutdownDevice])
    let refreshedSnapshot = MainWindowTestFixtures.makeSnapshot(devices: [bootedDevice])
    let bootResult = MainWindowTestFixtures.makeCommandResult(
      id: "bootstatus",
      arguments: ["simctl", "bootstatus", shutdownDevice.id, "-b"]
    )
    let setLocationResult = MainWindowTestFixtures.makeCommandResult(
      id: "set-location",
      arguments: [
        "simctl",
        "location",
        shutdownDevice.id,
        "set",
        "37.334900,-122.009020"
      ]
    )
    let refreshResult = MainWindowTestFixtures.makeRefreshResult(snapshot: refreshedSnapshot)
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: setLocationResult,
      remoteNotificationResult: setLocationResult,
      privacyResult: setLocationResult,
      setLocationResult: setLocationResult,
      clearLocationResult: setLocationResult
    )
    let commandState = DeviceCommandState(command: .setLocation, deviceID: shutdownDevice.id)
    let recentLocation = DeveloperToolsFeature.LocationCoordinateInput(
      name: "Apple Park",
      latitude: "37.334900",
      longitude: "-122.009020"
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: initialSnapshot,
        selectedDeviceID: shutdownDevice.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDeviceIfNeeded = { _ in
        bootResult
      }
      $0.coreSimulatorService.setLocation = { deviceID, coordinate in
        await recorder.setLocation(deviceID: deviceID, coordinate: coordinate)
      }
      $0.simulatorRepository.refresh = {
        refreshResult
      }
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.setLocationButtonTapped)))) {
      $0.workspace.deviceDetail.developerTools.recentLocations = [recentLocation]
      $0.workspace.setDeviceCommandState(commandState)
    }

    await store.receive(
      .developerToolCommandResults(
        commandState,
        [bootResult, setLocationResult],
        refreshAfterward: true
      )
    ) {
      $0.sidebar.refreshState = .refreshing
      $0.workspace.refreshState = .refreshing
    }

    await store.receive(
      .developerToolCommandRefreshResponse(
        commandState,
        refreshResult,
        preferredSelectedDeviceID: shutdownDevice.id
      )
    ) {
      $0.sidebar = SidebarFeature.State(snapshot: refreshedSnapshot, refreshState: .idle)
      $0.workspace.applySnapshot(
        refreshedSnapshot,
        refreshState: .idle,
        preferredSelectedDeviceID: shutdownDevice.id
      )
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.setLocationCalls() == [
      MainWindowSetLocationCall(
        deviceID: shutdownDevice.id,
        coordinate: "37.334900,-122.009020"
      )
    ])
  }

  @Test
  func statusBarOverrideOnBootedDeviceCompletesWithoutRefreshing() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "status-bar",
      arguments: [
        "simctl",
        "status_bar",
        device.id,
        "override",
        "--time",
        "09:41",
        "--batteryLevel",
        "100"
      ]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: commandResult,
      remoteNotificationResult: commandResult,
      privacyResult: commandResult,
      setLocationResult: commandResult,
      clearLocationResult: commandResult,
      statusBarResult: commandResult
    )
    let refreshRecorder = MainWindowRefreshRecorder(
      result: MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    )
    let commandState = DeviceCommandState(command: .statusBarOverride, deviceID: device.id)
    var initialState = MainWindowFeature.State(
      snapshot: snapshot,
      selectedDeviceID: device.id
    )
    initialState.workspace.deviceDetail.developerTools.statusBarTime = "09:41"
    initialState.workspace.deviceDetail.developerTools.statusBarBatteryLevel = "100"

    let store = TestStore(initialState: initialState) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.setStatusBarOverride = { deviceID, arguments in
        await recorder.setStatusBarOverride(deviceID: deviceID, arguments: arguments)
      }
      $0.simulatorRepository.refresh = {
        await refreshRecorder.refresh()
      }
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.setStatusBarOverrideButtonTapped)))) {
      $0.workspace.setDeviceCommandState(commandState)
    }

    await store.receive(
      .developerToolCommandResults(
        commandState,
        [commandResult],
        refreshAfterward: false
      )
    ) {
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.statusBarCalls() == [
      MainWindowStatusBarOverrideCall(
        deviceID: device.id,
        arguments: ["--time", "09:41", "--batteryLevel", "100"]
      )
    ])
    #expect(await refreshRecorder.refreshCallCount() == 0)
  }

  @Test
  func clearStatusBarOverrideOnBootedDeviceCompletesWithoutRefreshing() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "clear-status-bar",
      arguments: ["simctl", "status_bar", device.id, "clear"]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: commandResult,
      remoteNotificationResult: commandResult,
      privacyResult: commandResult,
      setLocationResult: commandResult,
      clearLocationResult: commandResult,
      clearStatusBarResult: commandResult
    )
    let refreshRecorder = MainWindowRefreshRecorder(
      result: MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    )
    let commandState = DeviceCommandState(command: .clearStatusBarOverride, deviceID: device.id)

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.clearStatusBarOverride = { deviceID in
        await recorder.clearStatusBarOverride(deviceID: deviceID)
      }
      $0.simulatorRepository.refresh = {
        await refreshRecorder.refresh()
      }
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.clearStatusBarOverrideButtonTapped)))) {
      $0.workspace.setDeviceCommandState(commandState)
    }

    await store.receive(
      .developerToolCommandResults(
        commandState,
        [commandResult],
        refreshAfterward: false
      )
    ) {
      $0.workspace.setDeviceCommandState(nil)
    }

    #expect(await recorder.clearStatusBarCalls() == [device.id])
    #expect(await refreshRecorder.refreshCallCount() == 0)
  }

  @Test
  func statusBarOverrideOnShutdownDeviceDoesNotBootOrRunCommand() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .shutdown)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "unexpected-status-bar",
      arguments: ["simctl", "status_bar", device.id, "override"]
    )
    let bootRecorder = MainWindowAppCommandRecorder()
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: commandResult,
      remoteNotificationResult: commandResult,
      privacyResult: commandResult,
      setLocationResult: commandResult,
      clearLocationResult: commandResult,
      statusBarResult: commandResult,
      clearStatusBarResult: commandResult
    )
    var initialState = MainWindowFeature.State(
      snapshot: snapshot,
      selectedDeviceID: device.id
    )
    initialState.workspace.deviceDetail.developerTools.statusBarTime = "09:41"

    let store = TestStore(initialState: initialState) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.bootDeviceIfNeeded = { id in
        await bootRecorder.bootDeviceIfNeeded(id: id)
      }
      $0.coreSimulatorService.setStatusBarOverride = { deviceID, arguments in
        await recorder.setStatusBarOverride(deviceID: deviceID, arguments: arguments)
      }
      $0.coreSimulatorService.clearStatusBarOverride = { deviceID in
        await recorder.clearStatusBarOverride(deviceID: deviceID)
      }
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.setStatusBarOverrideButtonTapped))))
    await store.send(.workspace(.deviceDetail(.developerTools(.clearStatusBarOverrideButtonTapped))))

    #expect(await bootRecorder.bootCalls() == [])
    #expect(await recorder.statusBarCalls() == [])
    #expect(await recorder.clearStatusBarCalls() == [])
  }

  @Test
  func invalidRemoteNotificationPayloadDoesNotRunCommand() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "unexpected-remote-notification",
      arguments: ["simctl", "push", device.id]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: commandResult,
      remoteNotificationResult: commandResult,
      privacyResult: commandResult,
      setLocationResult: commandResult,
      clearLocationResult: commandResult
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.coreSimulatorService.pushNotification = { deviceID, bundleID, payloadJSON in
        await recorder.remoteNotification(
          deviceID: deviceID,
          bundleID: bundleID,
          payloadJSON: payloadJSON
        )
      }
    }

    await store.send(
      .workspace(.deviceDetail(.developerTools(.remoteNotificationPayloadJSONChanged(#"{"alert":"Hello"}"#))))
    ) {
      $0.workspace.deviceDetail.developerTools.remoteNotificationPayloadJSON = #"{"alert":"Hello"}"#
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.sendRemoteNotificationButtonTapped))))

    #expect(await recorder.remoteNotificationCalls() == [])
  }
}
