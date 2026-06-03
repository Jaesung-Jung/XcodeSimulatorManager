import ComposableArchitecture
import DeveloperToolsFeature
import DeviceDetailFeature
import MainWindowFeatureSupport
import MenuBarFeature
import SimControlClients
import SimControlDomain
import SidebarFeature
import Foundation
import Testing
import WorkspaceFeature

@testable import MainWindowFeature

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
  func openAppBundleContainerUsesSimctlPathBeforeFallback() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let fallbackBundleContainer = URL(fileURLWithPath: "/tmp/FallbackBundle")
    let simctlAppPath = URL(fileURLWithPath: "/tmp/SimctlBundle/Example.app")
    let expectedOpenedPath = simctlAppPath.deletingLastPathComponent()
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app",
      bundleContainer: fallbackBundleContainer
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let getContainerResult = MainWindowTestFixtures.makeCommandResult(
      id: "get-app-container",
      arguments: ["simctl", "get_app_container", device.id, app.bundleID, "app"],
      stdout: "\(simctlAppPath.path)\n"
    )
    let openResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-bundle-container",
      executable: "SimControl",
      arguments: ["open-finder", expectedOpenedPath.path],
      stdout: "Opened app bundle container path: \(expectedOpenedPath.path)"
    )
    let recorder = MainWindowPathActionRecorder(
      getContainerResults: [getContainerResult],
      openResult: openResult
    )
    let refreshRecorder = MainWindowRefreshRecorder(
      result: MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
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
      $0.coreSimulatorService.getAppContainer = { deviceID, bundleID, container in
        await recorder.getAppContainer(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      }
      $0.pathAction.openInFinder = { url, label in
        await recorder.openInFinder(url, label: label)
      }
      $0.simulatorRepository.refresh = {
        await refreshRecorder.refresh()
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.openBundleContainerButtonTapped(app.id)))))

    await store.receive(.pathActionResults([getContainerResult, openResult])) {
      $0.workspace.appendCommandResult(getContainerResult)
      $0.workspace.appendCommandResult(openResult)
    }

    #expect(await recorder.getContainerCalls() == [
      MainWindowGetAppContainerCall(
        deviceID: device.id,
        bundleID: app.bundleID,
        container: .app
      )
    ])
    #expect(await recorder.openCalls() == [
      MainWindowOpenPathCall(url: expectedOpenedPath, label: "app bundle container")
    ])
    #expect(await refreshRecorder.refreshCallCount() == 0)
  }

  @Test
  func openAppDataContainerFallsBackToScannerPathWhenSimctlFails() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let dataContainer = URL(fileURLWithPath: "/tmp/AppData")
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app",
      dataContainer: dataContainer
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let getContainerResult = MainWindowTestFixtures.makeCommandResult(
      id: "failed-get-data-container",
      arguments: ["simctl", "get_app_container", device.id, app.bundleID, "data"],
      stderr: "No such app container.",
      exitCode: 1
    )
    let openResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-data-container",
      executable: "SimControl",
      arguments: ["open-finder", dataContainer.path],
      stdout: "Opened app data container path: \(dataContainer.path)"
    )
    let recorder = MainWindowPathActionRecorder(
      getContainerResults: [getContainerResult],
      openResult: openResult
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
      $0.coreSimulatorService.getAppContainer = { deviceID, bundleID, container in
        await recorder.getAppContainer(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      }
      $0.pathAction.openInFinder = { url, label in
        await recorder.openInFinder(url, label: label)
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.openDataContainerButtonTapped(app.id)))))

    await store.receive(.pathActionResults([getContainerResult, openResult])) {
      $0.workspace.appendCommandResult(getContainerResult)
      $0.workspace.appendCommandResult(openResult)
    }

    #expect(await recorder.openCalls() == [
      MainWindowOpenPathCall(url: dataContainer, label: "app data container")
    ])
  }

  @Test
  func copyAppGroupContainerUsesGroupIdentifierLookup() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let groupID = "group.com.example.shared"
    let scannerGroupPath = URL(fileURLWithPath: "/tmp/ScannerGroup")
    let simctlGroupPath = URL(fileURLWithPath: "/tmp/SimctlGroup")
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app",
      appGroups: [
        AppGroupContainer(
          id: "\(device.id):\(groupID)",
          groupID: groupID,
          path: scannerGroupPath
        )
      ]
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let getContainerResult = MainWindowTestFixtures.makeCommandResult(
      id: "get-app-group-container",
      arguments: ["simctl", "get_app_container", device.id, app.bundleID, groupID],
      stdout: "\(simctlGroupPath.path)\n"
    )
    let copyResult = MainWindowTestFixtures.makeCommandResult(
      id: "copy-app-group-path",
      executable: "SimControl",
      arguments: ["copy", simctlGroupPath.path],
      stdout: "Copied App Group \(groupID) container."
    )
    let recorder = MainWindowPathActionRecorder(
      getContainerResults: [getContainerResult],
      copyResult: copyResult
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
      $0.coreSimulatorService.getAppContainer = { deviceID, bundleID, container in
        await recorder.getAppContainer(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      }
      $0.pathAction.copyPath = { url, label in
        await recorder.copyPath(url, label: label)
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.copyAppGroupContainerButtonTapped(app.id, groupID)))))

    await store.receive(.pathActionResults([getContainerResult, copyResult])) {
      $0.workspace.appendCommandResult(getContainerResult)
      $0.workspace.appendCommandResult(copyResult)
    }

    #expect(await recorder.getContainerCalls() == [
      MainWindowGetAppContainerCall(
        deviceID: device.id,
        bundleID: app.bundleID,
        container: .appGroup(groupID)
      )
    ])
    #expect(await recorder.copyPathCalls() == [
      MainWindowCopyPathCall(
        url: simctlGroupPath,
        label: "App Group \(groupID) container"
      )
    ])
  }

  @Test
  func missingAppContainerFallbackRecordsFailureResult() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let app = MainWindowTestFixtures.makeInstalledApp(
      deviceID: device.id,
      bundleID: "com.example.app"
    )
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [device],
      installedAppsByDeviceID: [device.id: [app]]
    )
    let getContainerResult = MainWindowTestFixtures.makeCommandResult(
      id: "failed-get-data-container",
      arguments: ["simctl", "get_app_container", device.id, app.bundleID, "data"],
      stderr: "No such app container.",
      exitCode: 1
    )
    let openResult = MainWindowTestFixtures.makeCommandResult(
      id: "missing-data-container",
      executable: "SimControl",
      arguments: ["open-finder", "app data container"],
      stderr: "No app data container path is available.",
      exitCode: 1
    )
    let recorder = MainWindowPathActionRecorder(
      getContainerResults: [getContainerResult],
      openResult: openResult
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
      $0.coreSimulatorService.getAppContainer = { deviceID, bundleID, container in
        await recorder.getAppContainer(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      }
      $0.pathAction.openInFinder = { url, label in
        await recorder.openInFinder(url, label: label)
      }
    }

    await store.send(.workspace(.deviceDetail(.installedApps(.openDataContainerButtonTapped(app.id)))))

    await store.receive(.pathActionResults([getContainerResult, openResult])) {
      $0.workspace.appendCommandResult(getContainerResult)
      $0.workspace.appendCommandResult(openResult)
    }

    #expect(await recorder.openCalls() == [
      MainWindowOpenPathCall(url: nil, label: "app data container")
    ])
  }

  @Test
  func devicePathAndIdentifierActionsRecordResultsWithoutRefreshing() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let openResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-device-data",
      executable: "SimControl",
      arguments: ["open-finder", device.dataPath?.path ?? ""],
      stdout: "Opened device data folder path: \(device.dataPath?.path ?? "")"
    )
    let copyResult = MainWindowTestFixtures.makeCommandResult(
      id: "copy-device-udid",
      executable: "SimControl",
      arguments: ["copy", device.udid],
      stdout: "Copied device UDID."
    )
    let recorder = MainWindowPathActionRecorder(
      openResult: openResult,
      copyResult: copyResult
    )
    let refreshRecorder = MainWindowRefreshRecorder(
      result: MainWindowTestFixtures.makeRefreshResult(snapshot: snapshot)
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        selectedDeviceID: device.id
      )
    ) {
      MainWindowFeature()
    } withDependencies: {
      $0.pathAction.openInFinder = { url, label in
        await recorder.openInFinder(url, label: label)
      }
      $0.pathAction.copy = { value, label in
        await recorder.copy(value, label: label)
      }
      $0.simulatorRepository.refresh = {
        await refreshRecorder.refresh()
      }
    }

    await store.send(.workspace(.deviceDetail(.openDeviceDataFolderButtonTapped(device.id))))
    await store.receive(.pathActionResults([openResult])) {
      $0.workspace.appendCommandResult(openResult)
    }

    await store.send(.workspace(.deviceDetail(.copyDeviceUDIDButtonTapped(device.id))))
    await store.receive(.pathActionResults([copyResult])) {
      $0.workspace.appendCommandResult(copyResult)
    }

    #expect(await recorder.openCalls() == [
      MainWindowOpenPathCall(url: device.dataPath, label: "device data folder")
    ])
    #expect(await recorder.copyCalls() == [
      MainWindowCopyValueCall(value: device.udid, label: "device UDID")
    ])
    #expect(await refreshRecorder.refreshCallCount() == 0)
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

  @Test
  func openDeepLinkRecordsCommandResultWithoutRefreshing() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let openResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-url",
      arguments: ["simctl", "openurl", device.id, "myapp://home"]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: openResult,
      pushResult: openResult,
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
      $0.workspace.appendCommandResult(openResult)
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
      pushResult: setLocationResult,
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
      $0.workspace.appendCommandResult(bootResult)
      $0.workspace.appendCommandResult(setLocationResult)
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
        commandResults: [
          bootResult,
          setLocationResult,
          MainWindowTestFixtures.xcodeCommandResult,
          MainWindowTestFixtures.listCommandResult
        ],
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
  func statusBarOverrideOnBootedDeviceRecordsCommandResultWithoutRefreshing() async {
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
      pushResult: commandResult,
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
      $0.workspace.appendCommandResult(commandResult)
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
  func clearStatusBarOverrideOnBootedDeviceRecordsCommandResultWithoutRefreshing() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "clear-status-bar",
      arguments: ["simctl", "status_bar", device.id, "clear"]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: commandResult,
      pushResult: commandResult,
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
      $0.workspace.appendCommandResult(commandResult)
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
      pushResult: commandResult,
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
  func invalidPushPayloadDoesNotRunCommand() async {
    let device = MainWindowTestFixtures.makeDevice(id: "DEVICE", state: .booted)
    let snapshot = MainWindowTestFixtures.makeSnapshot(devices: [device])
    let commandResult = MainWindowTestFixtures.makeCommandResult(
      id: "unexpected-push",
      arguments: ["simctl", "push", device.id]
    )
    let recorder = MainWindowDeveloperToolCommandRecorder(
      openURLResult: commandResult,
      pushResult: commandResult,
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
        await recorder.pushNotification(
          deviceID: deviceID,
          bundleID: bundleID,
          payloadJSON: payloadJSON
        )
      }
    }

    await store.send(
      .workspace(.deviceDetail(.developerTools(.pushPayloadJSONChanged(#"{"alert":"Hello"}"#))))
    ) {
      $0.workspace.deviceDetail.developerTools.pushPayloadJSON = #"{"alert":"Hello"}"#
    }

    await store.send(.workspace(.deviceDetail(.developerTools(.sendPushButtonTapped))))

    #expect(await recorder.pushCalls() == [])
  }
}

private struct MainWindowAppCall: Equatable {
  let deviceID: String
  let bundleID: String
}

private struct MainWindowInstallAppCall: Equatable {
  let deviceID: String
  let appBundlePath: URL
}

private struct MainWindowGetAppContainerCall: Equatable {
  let deviceID: String
  let bundleID: String
  let container: SimulatorAppContainerKind
}

private struct MainWindowOpenPathCall: Equatable {
  let url: URL?
  let label: String
}

private struct MainWindowCopyPathCall: Equatable {
  let url: URL?
  let label: String
}

private struct MainWindowCopyValueCall: Equatable {
  let value: String?
  let label: String
}

private struct MainWindowOpenURLCall: Equatable {
  let deviceID: String
  let urlString: String
}

private struct MainWindowPushCall: Equatable {
  let deviceID: String
  let bundleID: String?
  let payloadJSON: String
}

private struct MainWindowPrivacyCall: Equatable {
  let deviceID: String
  let action: String
  let service: String
  let bundleID: String?
}

private struct MainWindowSetLocationCall: Equatable {
  let deviceID: String
  let coordinate: String
}

private struct MainWindowStatusBarOverrideCall: Equatable {
  let deviceID: String
  let arguments: [String]
}

private actor MainWindowDeveloperToolCommandRecorder {
  private let openURLResult: CommandResult
  private let pushResult: CommandResult
  private let privacyResult: CommandResult
  private let setLocationResult: CommandResult
  private let clearLocationResult: CommandResult
  private let statusBarResult: CommandResult
  private let clearStatusBarResult: CommandResult
  private var recordedOpenURLCalls: [MainWindowOpenURLCall] = []
  private var recordedPushCalls: [MainWindowPushCall] = []
  private var recordedPrivacyCalls: [MainWindowPrivacyCall] = []
  private var recordedSetLocationCalls: [MainWindowSetLocationCall] = []
  private var recordedClearLocationCalls: [String] = []
  private var recordedStatusBarCalls: [MainWindowStatusBarOverrideCall] = []
  private var recordedClearStatusBarCalls: [String] = []

  init(
    openURLResult: CommandResult,
    pushResult: CommandResult,
    privacyResult: CommandResult,
    setLocationResult: CommandResult,
    clearLocationResult: CommandResult,
    statusBarResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "status-bar",
      arguments: ["simctl", "status_bar", "DEVICE", "override"]
    ),
    clearStatusBarResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "clear-status-bar",
      arguments: ["simctl", "status_bar", "DEVICE", "clear"]
    )
  ) {
    self.openURLResult = openURLResult
    self.pushResult = pushResult
    self.privacyResult = privacyResult
    self.setLocationResult = setLocationResult
    self.clearLocationResult = clearLocationResult
    self.statusBarResult = statusBarResult
    self.clearStatusBarResult = clearStatusBarResult
  }

  func openURL(deviceID: String, urlString: String) -> CommandResult {
    recordedOpenURLCalls.append(
      MainWindowOpenURLCall(deviceID: deviceID, urlString: urlString)
    )
    return openURLResult
  }

  func pushNotification(
    deviceID: String,
    bundleID: String?,
    payloadJSON: String
  ) -> CommandResult {
    recordedPushCalls.append(
      MainWindowPushCall(
        deviceID: deviceID,
        bundleID: bundleID,
        payloadJSON: payloadJSON
      )
    )
    return pushResult
  }

  func setPrivacyPermission(
    deviceID: String,
    action: String,
    service: String,
    bundleID: String?
  ) -> CommandResult {
    recordedPrivacyCalls.append(
      MainWindowPrivacyCall(
        deviceID: deviceID,
        action: action,
        service: service,
        bundleID: bundleID
      )
    )
    return privacyResult
  }

  func setLocation(deviceID: String, coordinate: String) -> CommandResult {
    recordedSetLocationCalls.append(
      MainWindowSetLocationCall(deviceID: deviceID, coordinate: coordinate)
    )
    return setLocationResult
  }

  func clearLocation(deviceID: String) -> CommandResult {
    recordedClearLocationCalls.append(deviceID)
    return clearLocationResult
  }

  func setStatusBarOverride(deviceID: String, arguments: [String]) -> CommandResult {
    recordedStatusBarCalls.append(
      MainWindowStatusBarOverrideCall(deviceID: deviceID, arguments: arguments)
    )
    return statusBarResult
  }

  func clearStatusBarOverride(deviceID: String) -> CommandResult {
    recordedClearStatusBarCalls.append(deviceID)
    return clearStatusBarResult
  }

  func openURLCalls() -> [MainWindowOpenURLCall] {
    recordedOpenURLCalls
  }

  func pushCalls() -> [MainWindowPushCall] {
    recordedPushCalls
  }

  func privacyCalls() -> [MainWindowPrivacyCall] {
    recordedPrivacyCalls
  }

  func setLocationCalls() -> [MainWindowSetLocationCall] {
    recordedSetLocationCalls
  }

  func clearLocationCalls() -> [String] {
    recordedClearLocationCalls
  }

  func statusBarCalls() -> [MainWindowStatusBarOverrideCall] {
    recordedStatusBarCalls
  }

  func clearStatusBarCalls() -> [String] {
    recordedClearStatusBarCalls
  }
}

private actor MainWindowPathActionRecorder {
  private var getContainerResults: [CommandResult]
  private let openResult: CommandResult
  private let copyResult: CommandResult
  private var recordedGetContainerCalls: [MainWindowGetAppContainerCall] = []
  private var recordedOpenCalls: [MainWindowOpenPathCall] = []
  private var recordedCopyPathCalls: [MainWindowCopyPathCall] = []
  private var recordedCopyCalls: [MainWindowCopyValueCall] = []

  init(
    getContainerResults: [CommandResult] = [],
    openResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "open-path",
      executable: "SimControl",
      arguments: ["open-finder", "/tmp"]
    ),
    copyResult: CommandResult = MainWindowTestFixtures.makeCommandResult(
      id: "copy-path",
      executable: "SimControl",
      arguments: ["copy", "/tmp"]
    )
  ) {
    self.getContainerResults = getContainerResults
    self.openResult = openResult
    self.copyResult = copyResult
  }

  func getAppContainer(
    deviceID: String,
    bundleID: String,
    container: SimulatorAppContainerKind
  ) -> CommandResult {
    recordedGetContainerCalls.append(
      MainWindowGetAppContainerCall(
        deviceID: deviceID,
        bundleID: bundleID,
        container: container
      )
    )

    guard !getContainerResults.isEmpty else {
      return MainWindowTestFixtures.makeCommandResult(
        id: "missing-get-container-result",
        arguments: ["simctl", "get_app_container", deviceID, bundleID, container.simctlArgument],
        stderr: "No test get_app_container result was provided.",
        exitCode: 1
      )
    }

    return getContainerResults.removeFirst()
  }

  func openInFinder(_ url: URL?, label: String) -> CommandResult {
    recordedOpenCalls.append(MainWindowOpenPathCall(url: url, label: label))
    return openResult
  }

  func copyPath(_ url: URL?, label: String) -> CommandResult {
    recordedCopyPathCalls.append(MainWindowCopyPathCall(url: url, label: label))
    return copyResult
  }

  func copy(_ value: String?, label: String) -> CommandResult {
    recordedCopyCalls.append(MainWindowCopyValueCall(value: value, label: label))
    return copyResult
  }

  func getContainerCalls() -> [MainWindowGetAppContainerCall] {
    recordedGetContainerCalls
  }

  func openCalls() -> [MainWindowOpenPathCall] {
    recordedOpenCalls
  }

  func copyPathCalls() -> [MainWindowCopyPathCall] {
    recordedCopyPathCalls
  }

  func copyCalls() -> [MainWindowCopyValueCall] {
    recordedCopyCalls
  }
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
