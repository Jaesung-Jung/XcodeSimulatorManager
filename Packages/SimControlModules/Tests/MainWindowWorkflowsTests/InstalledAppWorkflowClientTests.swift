import Foundation
import MainWindowWorkflows
import SimControlClients
import SimControlDomain
import Testing

@Suite("InstalledAppWorkflowClient")
struct InstalledAppWorkflowClientTests {
  @Test("launch app on shutdown device boots, launches, refreshes, and preserves selection")
  func launchAppOnShutdownDeviceBootsThenLaunchesAndRefreshes() async {
    let recorder = InstalledAppWorkflowRecorder()
    let bootResult = makeCommandResult(id: "boot")
    let launchResult = makeCommandResult(id: "launch")
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.bootDeviceIfNeeded = { deviceID in
      await recorder.record(.boot(deviceID))
      return bootResult
    }
    coreSimulator.launchApp = { deviceID, bundleID in
      await recorder.record(.launch(deviceID, bundleID))
      return launchResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = InstalledAppWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      appSandboxReset: AppSandboxResetClient.testValue,
      simulatorRepository: repository
    )

    let result = await workflow.launchApp(
      "DEVICE-1",
      "DEVICE-1:com.example.app",
      "com.example.app",
      .shutdown
    )

    #expect(result == InstalledAppWorkflowResult(
      commandResults: [bootResult, launchResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "DEVICE-1",
      preferredSelectedAppID: "DEVICE-1:com.example.app"
    ))
    #expect(await recorder.operations() == [
      .boot("DEVICE-1"),
      .launch("DEVICE-1", "com.example.app"),
      .refresh
    ])
  }

  @Test("failed launch boot skips launch but still refreshes and preserves selection")
  func failedLaunchBootSkipsLaunchAndStillRefreshes() async {
    let recorder = InstalledAppWorkflowRecorder()
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
    coreSimulator.launchApp = { deviceID, bundleID in
      await recorder.record(.launch(deviceID, bundleID))
      return makeCommandResult(id: "unexpected-launch")
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = InstalledAppWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      appSandboxReset: AppSandboxResetClient.testValue,
      simulatorRepository: repository
    )

    let result = await workflow.launchApp(
      "DEVICE-1",
      "DEVICE-1:com.example.app",
      "com.example.app",
      .shutdown
    )

    #expect(result == InstalledAppWorkflowResult(
      commandResults: [bootResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "DEVICE-1",
      preferredSelectedAppID: "DEVICE-1:com.example.app"
    ))
    #expect(await recorder.operations() == [
      .boot("DEVICE-1"),
      .refresh
    ])
  }

  @Test("successful uninstall clears preferred app selection")
  func successfulUninstallClearsPreferredAppSelection() async {
    let recorder = InstalledAppWorkflowRecorder()
    let uninstallResult = makeCommandResult(id: "uninstall")
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.uninstallApp = { deviceID, bundleID in
      await recorder.record(.uninstall(deviceID, bundleID))
      return uninstallResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = InstalledAppWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      appSandboxReset: AppSandboxResetClient.testValue,
      simulatorRepository: repository
    )

    let result = await workflow.uninstallApp(
      "DEVICE-1",
      "DEVICE-1:com.example.app",
      "com.example.app"
    )

    #expect(result == InstalledAppWorkflowResult(
      commandResults: [uninstallResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "DEVICE-1",
      preferredSelectedAppID: nil
    ))
    #expect(await recorder.operations() == [
      .uninstall("DEVICE-1", "com.example.app"),
      .refresh
    ])
  }

  @Test("reset sandbox uses sandbox reset client and preserves selection")
  func resetSandboxUsesSandboxResetClientAndPreservesSelection() async {
    let recorder = InstalledAppWorkflowRecorder()
    let dataContainer = URL(fileURLWithPath: "/tmp/data-container")
    let resetResult = makeCommandResult(id: "reset")
    let refreshResult = makeRefreshResult(id: "refresh")
    var appSandboxReset = AppSandboxResetClient.testValue
    appSandboxReset.resetSandbox = { url in
      await recorder.record(.resetSandbox(url))
      return resetResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = InstalledAppWorkflowClient.live(
      coreSimulatorService: CoreSimulatorClient.testValue,
      appSandboxReset: appSandboxReset,
      simulatorRepository: repository
    )

    let result = await workflow.resetSandbox(
      "DEVICE-1",
      "DEVICE-1:com.example.app",
      dataContainer
    )

    #expect(result == InstalledAppWorkflowResult(
      commandResults: [resetResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "DEVICE-1",
      preferredSelectedAppID: "DEVICE-1:com.example.app"
    ))
    #expect(await recorder.operations() == [
      .resetSandbox(dataContainer),
      .refresh
    ])
  }

  @Test("install app boots target, installs, launches, refreshes, and selects target app")
  func installAppBootsInstallsLaunchesAndSelectsTargetApp() async {
    let recorder = InstalledAppWorkflowRecorder()
    let appBundlePath = URL(fileURLWithPath: "/tmp/Example.app")
    let bootResult = makeCommandResult(id: "boot")
    let installResult = makeCommandResult(id: "install")
    let launchResult = makeCommandResult(id: "launch")
    let refreshResult = makeRefreshResult(id: "refresh")
    var coreSimulator = CoreSimulatorClient.testValue
    coreSimulator.bootDeviceIfNeeded = { deviceID in
      await recorder.record(.boot(deviceID))
      return bootResult
    }
    coreSimulator.installApp = { deviceID, path in
      await recorder.record(.install(deviceID, path))
      return installResult
    }
    coreSimulator.launchApp = { deviceID, bundleID in
      await recorder.record(.launch(deviceID, bundleID))
      return launchResult
    }
    var repository = SimulatorRepositoryClient.testValue
    repository.refresh = {
      await recorder.record(.refresh)
      return refreshResult
    }
    let workflow = InstalledAppWorkflowClient.live(
      coreSimulatorService: coreSimulator,
      appSandboxReset: AppSandboxResetClient.testValue,
      simulatorRepository: repository
    )

    let result = await workflow.installAppOnSimulator(
      InstallAppOnSimulatorWorkflowRequest(
        targetDeviceID: "TARGET-1",
        targetDeviceState: .shutdown,
        bundleID: "com.example.app",
        appBundlePath: appBundlePath,
        launchAfterInstall: true
      )
    )

    #expect(result == InstalledAppWorkflowResult(
      commandResults: [bootResult, installResult, launchResult],
      refreshResult: refreshResult,
      preferredSelectedDeviceID: "TARGET-1",
      preferredSelectedAppID: "TARGET-1:com.example.app"
    ))
    #expect(await recorder.operations() == [
      .boot("TARGET-1"),
      .install("TARGET-1", appBundlePath),
      .launch("TARGET-1", "com.example.app"),
      .refresh
    ])
  }
}

private enum InstalledAppWorkflowOperation: Equatable, Sendable {
  case boot(String)
  case launch(String, String)
  case uninstall(String, String)
  case install(String, URL)
  case resetSandbox(URL)
  case refresh
}

private actor InstalledAppWorkflowRecorder {
  private var recordedOperations: [InstalledAppWorkflowOperation] = []

  func record(_ operation: InstalledAppWorkflowOperation) {
    recordedOperations.append(operation)
  }

  func operations() -> [InstalledAppWorkflowOperation] {
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
