import Foundation
import MainWindowWorkflows
import SimControlClients
import SimControlDomain
import Testing

@Suite("DeveloperToolWorkflowClient")
struct DeveloperToolWorkflowClientTests {
  @Test("open URL on shutdown device boots, opens URL, refreshes, and prefers device")
  func openURLOnShutdownDeviceBootsOpensRefreshesAndPrefersDevice() async {
    let recorder = DeveloperToolWorkflowRecorder()
    let bootResult = makeCommandResult(id: "boot")
    let openResult = makeCommandResult(id: "open-url")
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.bootDeviceIfNeeded = { deviceID in
      await recorder.record(.boot(deviceID))
      return bootResult
    }
    coreSimulator.openURL = { deviceID, urlString in
      await recorder.record(.openURL(deviceID, urlString))
      return openResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = DeveloperToolWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: repository
    )

    let result = await workflow.openURL(
      "DEVICE-1",
      .shutdown,
      "example://path"
    )

    #expect(result == DeveloperToolWorkflowResult(
      commandResults: [bootResult, openResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "DEVICE-1"
    ))
    #expect(await recorder.operations() == [
      .boot("DEVICE-1"),
      .openURL("DEVICE-1", "example://path"),
      .refresh
    ])
  }

  @Test("failed boot skips developer command but still refreshes")
  func failedBootSkipsDeveloperCommandButStillRefreshes() async {
    let recorder = DeveloperToolWorkflowRecorder()
    let bootResult = makeCommandResult(
      id: "boot-failed",
      stderr: "boot failed",
      exitCode: 1
    )
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.bootDeviceIfNeeded = { deviceID in
      await recorder.record(.boot(deviceID))
      return bootResult
    }
    coreSimulator.setLocation = { deviceID, coordinate in
      await recorder.record(.setLocation(deviceID, coordinate))
      return makeCommandResult(id: "unexpected-location")
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = DeveloperToolWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: repository
    )

    let result = await workflow.setLocation(
      "DEVICE-1",
      .shutdown,
      "37.000000,127.000000"
    )

    #expect(result == DeveloperToolWorkflowResult(
      commandResults: [bootResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "DEVICE-1"
    ))
    #expect(await recorder.operations() == [
      .boot("DEVICE-1"),
      .refresh
    ])
  }

  @Test("remote notification on booted device runs command without refresh")
  func sendRemoteNotificationOnBootedDeviceRunsCommandWithoutRefresh() async {
    let recorder = DeveloperToolWorkflowRecorder()
    let remoteNotificationResult = makeCommandResult(id: "remote-notification")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.pushNotification = { deviceID, bundleID, payloadJSON in
      await recorder.record(.remoteNotification(deviceID, bundleID, payloadJSON))
      return remoteNotificationResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return makeRefreshResult(id: "unexpected-refresh")
    }
    let workflow = DeveloperToolWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: repository
    )

    let result = await workflow.sendRemoteNotification(
      "DEVICE-1",
      .booted,
      "com.example.app",
      #"{"aps":{"alert":"Hello"}}"#
    )

    #expect(result == DeveloperToolWorkflowResult(
      commandResults: [remoteNotificationResult],
      refreshResult: nil,
      preferredSelectedDeviceID: nil
    ))
    #expect(await recorder.operations() == [
      .remoteNotification(
        "DEVICE-1",
        "com.example.app",
        #"{"aps":{"alert":"Hello"}}"#
      )
    ])
  }

  @Test("status bar override requires booted device command and does not refresh")
  func statusBarOverrideRunsBootedCommandWithoutRefresh() async {
    let recorder = DeveloperToolWorkflowRecorder()
    let statusResult = makeCommandResult(id: "status")
    let arguments = ["--time", "09:41", "--batteryLevel", "100"]
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.setStatusBarOverride = { deviceID, arguments in
      await recorder.record(.statusBarOverride(deviceID, arguments))
      return statusResult
    }
    let workflow = DeveloperToolWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      simulatorRepository: SimulatorRepositoryClient.testValue
    )

    let result = await workflow.setStatusBarOverride(
      "DEVICE-1",
      arguments
    )

    #expect(result == DeveloperToolWorkflowResult(
      commandResults: [statusResult],
      refreshResult: nil,
      preferredSelectedDeviceID: nil
    ))
    #expect(await recorder.operations() == [
      .statusBarOverride("DEVICE-1", arguments)
    ])
  }
}

private enum DeveloperToolWorkflowOperation: Equatable, Sendable {
  case boot(String)
  case openURL(String, String)
  case remoteNotification(String, String?, String)
  case setLocation(String, String)
  case statusBarOverride(String, [String])
  case refresh
}

private actor DeveloperToolWorkflowRecorder {
  private var recordedOperations: [DeveloperToolWorkflowOperation] = []

  func record(_ operation: DeveloperToolWorkflowOperation) {
    recordedOperations.append(operation)
  }

  func operations() -> [DeveloperToolWorkflowOperation] {
    recordedOperations
  }
}

private func makeRefreshResult(id: String) -> SimulatorRefreshResult {
  SimulatorRefreshResult(
    snapshot: nil,
    xcodeCommandResult: makeCommandResult(id: "\(id)-xcode"),
    listCommandResult: makeCommandResult(id: "\(id)-list"),
    diagnostic: nil
  )
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
