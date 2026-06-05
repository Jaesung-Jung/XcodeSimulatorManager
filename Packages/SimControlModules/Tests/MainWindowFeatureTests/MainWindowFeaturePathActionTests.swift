import ComposableArchitecture
import SimControlDomain
import Foundation
import Testing

@testable import MainWindowFeature

@MainActor
struct MainWindowFeaturePathActionTests {
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

    await store.receive(.pathActionResults([getContainerResult, openResult]))

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

    await store.receive(.pathActionResults([getContainerResult, openResult]))

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

    await store.receive(.pathActionResults([getContainerResult, copyResult]))

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

    await store.receive(.pathActionResults([getContainerResult, openResult]))

    #expect(await recorder.openCalls() == [
      MainWindowOpenPathCall(url: nil, label: "app data container")
    ])
  }

  @Test
  func devicePathAndIdentifierActionsCompleteWithoutRefreshing() async {
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
    await store.receive(.pathActionResults([openResult]))

    await store.send(.workspace(.deviceDetail(.copyDeviceUDIDButtonTapped(device.id))))
    await store.receive(.pathActionResults([copyResult]))

    #expect(await recorder.openCalls() == [
      MainWindowOpenPathCall(url: device.dataPath, label: "device data folder")
    ])
    #expect(await recorder.copyCalls() == [
      MainWindowCopyValueCall(value: device.udid, label: "device UDID")
    ])
    #expect(await refreshRecorder.refreshCallCount() == 0)
  }
}
