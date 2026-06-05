import ComposableArchitecture
import MainWindowFeatureSupport
import SidebarFeature
import Foundation
import Testing
import WorkspaceFeature

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureAppCommandTests {
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
        preferredSelectedDeviceID: device.id,
        preferredSelectedAppID: app.id
      )
      $0.workspace.setAppCommandState(nil)
    }
  }
}
