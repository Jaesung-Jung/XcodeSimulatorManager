import ComposableArchitecture
import Foundation
import MainWindowFeatureSupport
import MenuBarFeature
import SidebarFeature
import Testing
import WorkspaceFeature

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureMenuBarTests {
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

    await store.send(.menuBar(.presented(at: now))) {
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

    await store.send(.menuBar(.presented(at: now)))

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

    await store.send(.menuBar(.presented(at: now))) {
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

    await store.send(.menuBar(.presented(at: now))) {
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

    await store.send(.menuBar(.presented(at: now.addingTimeInterval(30))))

    #expect(await recorder.refreshCallCount() == 1)
  }

  @Test
  func menuBarDeviceSelectionUpdatesWorkspaceSelection() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      devices: [
        MainWindowTestFixtures.device,
        MainWindowTestFixtures.secondDevice
      ]
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(snapshot: snapshot)
    ) {
      MainWindowFeature()
    }

    await store.send(.menuBar(.deviceSelected(MainWindowTestFixtures.secondDevice.id))) {
      $0.workspace.selectDevice(id: MainWindowTestFixtures.secondDevice.id)
    }
  }

  @Test
  func menuBarAppSelectionUpdatesWorkspaceDeviceAndAppSelection() async {
    let snapshot = MainWindowTestFixtures.makeSnapshot(
      installedAppsByDeviceID: [
        MainWindowTestFixtures.device.id: [MainWindowTestFixtures.app]
      ]
    )

    let store = TestStore(
      initialState: MainWindowFeature.State(
        snapshot: snapshot,
        installedAppsAvailability: .loaded
      )
    ) {
      MainWindowFeature()
    }

    await store.send(
      .menuBar(
        .appSelected(
          deviceID: MainWindowTestFixtures.device.id,
          appID: MainWindowTestFixtures.app.id
        )
      )
    ) {
      $0.workspace.selectDevice(id: MainWindowTestFixtures.device.id)
      $0.workspace.selectApp(id: MainWindowTestFixtures.app.id)
    }
  }
}
