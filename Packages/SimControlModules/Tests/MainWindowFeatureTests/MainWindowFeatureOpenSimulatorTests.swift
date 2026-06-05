import ComposableArchitecture
import Testing

@testable import MainWindowFeature

@MainActor
struct MainWindowFeatureOpenSimulatorTests {
  @Test
  func openSimulatorAppClearsRunningStateWithoutRecordingCommandHistory() async {
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
      $0.workspace.setOpeningSimulatorApp(false)
    }
  }
}
