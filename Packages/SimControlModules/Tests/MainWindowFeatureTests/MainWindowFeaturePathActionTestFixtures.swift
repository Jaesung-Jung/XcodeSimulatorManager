import Foundation
import SimControlDomain

struct MainWindowGetAppContainerCall: Equatable {
  let deviceID: String
  let bundleID: String
  let container: SimulatorAppContainerKind
}

struct MainWindowOpenPathCall: Equatable {
  let url: URL?
  let label: String
}

struct MainWindowCopyPathCall: Equatable {
  let url: URL?
  let label: String
}

struct MainWindowCopyValueCall: Equatable {
  let value: String?
  let label: String
}

actor MainWindowPathActionRecorder {
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
