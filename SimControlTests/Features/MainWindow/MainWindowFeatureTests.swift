import ComposableArchitecture
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
}
