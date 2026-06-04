import Foundation
import MainWindowWorkflows
import SimControlClients
import SimControlDomain
import Testing

@Suite("PathActionWorkflowClient")
struct PathActionWorkflowClientTests {
  @Test("device path action runs requested path operation")
  func devicePathActionRunsRequestedPathOperation() async {
    let recorder = PathActionRecorder()
    let expectedResult = makeCommandResult(id: "open-path")
    var pathAction = PathActionClient.testValue
    pathAction.openInFinder = { url, label in
      await recorder.recordOpen(url: url, label: label)
      return expectedResult
    }
    let workflow = PathActionWorkflowClient.live(
      coreSimulatorService: CoreSimulatorClient.testValue,
      pathAction: pathAction
    )
    let url = URL(fileURLWithPath: "/tmp/device/data")

    let results = await workflow.runDevicePathAction(url, "device data", .open)

    #expect(results == [expectedResult])
    #expect(await recorder.openCalls() == [
      PathActionCall(url: url, label: "device data")
    ])
  }

  @Test("app container action prefers simctl path and normalizes bundle container")
  func appContainerActionPrefersSimctlPathAndNormalizesBundleContainer() async {
    let coreRecorder = AppContainerRecorder()
    let pathRecorder = PathActionRecorder()
    let getContainerResult = makeCommandResult(
      id: "get-container",
      stdout: "/tmp/Bundle/Example.app\n"
    )
    let openResult = makeCommandResult(id: "open-container")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.getAppContainer = { deviceID, bundleID, container in
      await coreRecorder.record(
        deviceID: deviceID,
        bundleID: bundleID,
        container: container
      )
      return getContainerResult
    }
    var pathAction = PathActionClient.testValue
    pathAction.openInFinder = { url, label in
      await pathRecorder.recordOpen(url: url, label: label)
      return openResult
    }
    let workflow = PathActionWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      pathAction: pathAction
    )

    let results = await workflow.runAppContainerPathAction(
      AppContainerPathActionRequest(
        deviceID: "DEVICE-1",
        bundleID: "com.example.app",
        container: .app,
        fallbackURL: URL(fileURLWithPath: "/fallback/bundle"),
        label: "app bundle container",
        operation: .open
      )
    )

    #expect(results == [getContainerResult, openResult])
    #expect(await coreRecorder.calls() == [
      AppContainerCall(
        deviceID: "DEVICE-1",
        bundleID: "com.example.app",
        container: .app
      )
    ])
    #expect(await pathRecorder.openCalls() == [
      PathActionCall(
        url: URL(fileURLWithPath: "/tmp/Bundle/"),
        label: "app bundle container"
      )
    ])
  }

  @Test("app container action falls back when simctl lookup fails")
  func appContainerActionFallsBackWhenSimctlLookupFails() async {
    let pathRecorder = PathActionRecorder()
    let getContainerResult = makeCommandResult(
      id: "get-container-failed",
      stderr: "missing container",
      exitCode: 1
    )
    let copyResult = makeCommandResult(id: "copy-container")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.getAppContainer = { _, _, _ in
      getContainerResult
    }
    var pathAction = PathActionClient.testValue
    pathAction.copyPath = { url, label in
      await pathRecorder.recordCopyPath(url: url, label: label)
      return copyResult
    }
    let workflow = PathActionWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      pathAction: pathAction
    )
    let fallbackURL = URL(fileURLWithPath: "/fallback/data")

    let results = await workflow.runAppContainerPathAction(
      AppContainerPathActionRequest(
        deviceID: "DEVICE-1",
        bundleID: "com.example.app",
        container: .data,
        fallbackURL: fallbackURL,
        label: "app data container",
        operation: .copy
      )
    )

    #expect(results == [getContainerResult, copyResult])
    #expect(await pathRecorder.copyPathCalls() == [
      PathActionCall(url: fallbackURL, label: "app data container")
    ])
  }
}

extension PathActionWorkflowClientTests {
  private struct AppContainerCall: Equatable, Sendable {
    let deviceID: String
    let bundleID: String
    let container: SimulatorAppContainerKind
  }

  private struct PathActionCall: Equatable, Sendable {
    let url: URL?
    let label: String
  }

  private actor AppContainerRecorder {
    private var recordedCalls: [AppContainerCall] = []

    func record(
      deviceID: String,
      bundleID: String,
      container: SimulatorAppContainerKind
    ) {
      recordedCalls.append(
        AppContainerCall(
          deviceID: deviceID,
          bundleID: bundleID,
          container: container
        )
      )
    }

    func calls() -> [AppContainerCall] {
      recordedCalls
    }
  }

  private actor PathActionRecorder {
    private var recordedOpenCalls: [PathActionCall] = []
    private var recordedCopyPathCalls: [PathActionCall] = []

    func recordOpen(url: URL?, label: String) {
      recordedOpenCalls.append(PathActionCall(url: url, label: label))
    }

    func recordCopyPath(url: URL?, label: String) {
      recordedCopyPathCalls.append(PathActionCall(url: url, label: label))
    }

    func openCalls() -> [PathActionCall] {
      recordedOpenCalls
    }

    func copyPathCalls() -> [PathActionCall] {
      recordedCopyPathCalls
    }
  }

  private func makeCommandResult(
    id: String,
    stdout: String = "",
    stderr: String = "",
    exitCode: Int32 = 0
  ) -> CommandResult {
    CommandResult(
      id: id,
      executable: "test",
      arguments: [id],
      stdout: stdout,
      stderr: stderr,
      exitCode: exitCode,
      duration: 0,
      startedAt: Date(timeIntervalSince1970: 0)
    )
  }
}
